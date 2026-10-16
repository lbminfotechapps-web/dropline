import 'dart:async';

import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/dashboard_greeting.dart';
import '../widgets/dashboard_date_card.dart';
import '../widgets/dashboard_project_card.dart';
import '../widgets/dashboard_clock_card.dart';
import '../widgets/dashboard_slide_button.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DateTime _currentTime;
  Timer? _clockTimer;

  // Temporary UI values.
  // Later these will come from authentication/dashboard BLoC.
  final String _userName = 'Leo';
  ProjectEntity? _selectedProject;
  bool _isPreparingPunchIn = false;

  @override
  void initState() {
    super.initState();

    _currentTime = DateTime.now();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final now = DateTime.now();

      // Update when minute or date changes.
      if (now.minute != _currentTime.minute ||
          now.hour != _currentTime.hour ||
          now.day != _currentTime.day ||
          now.month != _currentTime.month ||
          now.year != _currentTime.year) {
        setState(() {
          _currentTime = now;
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // =========================================
  // SELECT PROJECT
  // =========================================

  // ==========================================
  // SEARCH PROJECT
  // ==========================================

  void _onProjectSelected(ProjectEntity project) {
    setState(() {
      _selectedProject = project;
    });

    debugPrint('Selected Project ID: ${project.projectId}');
    debugPrint('Selected Project Name: ${project.projectName}');
  }
  // =========================================
  // CLOCK IN / CLOCK OUT
  // =========================================

  Future<void> _onSlideCompleted() async {
    final bloc = context.read<DashboardBloc>();
    if (_isPreparingPunchIn ||
        bloc.state.punchInStatus == DashboardStatus.loading) {
      return;
    }

    final project = _selectedProject;
    if (project == null) {
      _showMessage('Please select a project first.');
      return;
    }

    setState(() => _isPreparingPunchIn = true);
    try {
      final login = await sl<SecureStorage>().readLoginResponse();
      if (!mounted) return;
      if (login == null ||
          !login.status ||
          login.result.isEmpty ||
          login.result.first.userId.trim().isEmpty) {
        _showMessage('Please sign in again before clocking in.');
        return;
      }
      bloc.add(
        PunchInEvent(
          loginUserId: login.result.first.userId,
          projectName: project.projectName,
          projectId: project.projectId,
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to read your session. Please sign in again.');
      }
    } finally {
      if (mounted) setState(() => _isPreparingPunchIn = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardBloc, DashboardState>(
      listenWhen: (previous, current) =>
          previous.punchInStatus != current.punchInStatus,
      listener: (context, state) {
        if (state.punchInStatus == DashboardStatus.failure) {
          _showMessage(state.errorMessage);
        } else if (state.punchInStatus == DashboardStatus.success) {
          context.push(AppRouter.punchOut);
        }
      },
      builder: (context, state) => _buildDashboard(context, state),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardState state) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / 591;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      42 * scale,
                      52 * scale,
                      42 * scale,
                      40 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Greeting
                            DashboardGreeting(
                              name: _userName,
                              dateTime: _currentTime,
                            ),

                            SizedBox(height: 100 * scale),

                            DashboardDateCard(date: _currentTime),

                            SizedBox(height: 51 * scale),

                            DashboardProjectCard(
                              selectedProject: _selectedProject,
                              onProjectSelected: _onProjectSelected,
                              onRemoveProject: () {
                                setState(() {
                                  _selectedProject = null;
                                });
                              },
                            ),
                            SizedBox(height: 62 * scale),

                            DashboardClockCard(dateTime: _currentTime),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 80 * scale),

                            DashboardSlideButton(
                              isLoading:
                                  _isPreparingPunchIn ||
                                  state.punchInStatus ==
                                      DashboardStatus.loading,
                              onCompleted: _onSlideCompleted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
