import 'package:dropline/core/utility/showcase_once.dart';
import 'dart:async';

import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:dropline/features/dashboard/presentation/widgets/dashboard_background.dart';
import 'package:dropline/features/punch/presentation/pages/punch_out.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';

import '../widgets/dashboard_greeting.dart';
import '../widgets/dashboard_project_card.dart';
import '../widgets/dashboard_clock_card.dart';
import '../widgets/dashboard_slide_button.dart';
import '../widgets/clock_in_confirmation_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _projectShowcaseKey = GlobalKey();
  late final String _showcaseScope;
  late final ShowcaseView _showcaseView;
  late DateTime _currentTime;
  Timer? _clockTimer;
  DateTime? _lastBackPressed;
  WorkspaceType _selectedWorkspace = WorkspaceType.personal;

  DateTime? _editedClockInTime;

  DateTime get _displayClockInTime => _editedClockInTime ?? _currentTime;
  ProjectEntity? _selectedProject;
  bool _isPreparingPunchIn = false;
  bool _isLoggingOut = false;

  String _userName = '';

  @override
  void initState() {
    super.initState();
    _showcaseScope = 'dashboard-${identityHashCode(this)}';
    _showcaseView = ShowcaseView.register(
      scope: _showcaseScope,
      enableAutoScroll: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseOnce.show(
        id: 'select_project',
        showcase: _showcaseView,
        target: _projectShowcaseKey,
        isMounted: () => mounted,
      );
    });

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

    loadLoginInData();
  }

  Future<void> _editClockInTime() async {
    final selectedTime = await DashboardTimeBottomSheet.show(
      context: context,
      initialTime: _displayClockInTime,
      workspaceLabel: _selectedWorkspace == WorkspaceType.personal
          ? 'Personal · Private'
          : 'Business · Shared projects',
    );

    if (!mounted || selectedTime == null) return;

    setState(() {
      _editedClockInTime = selectedTime;
    });
  }

  @override
  void dispose() {
    _showcaseView.unregister();
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
    if (_isLoggingOut ||
        _isPreparingPunchIn ||
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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ClockInConfirmationDialog(
          workspace: _selectedWorkspace == WorkspaceType.personal
              ? 'Personal'
              : 'Business',
          projectName: project.projectName,
          clockInTime: _displayClockInTime,
        ),
      );
      if (!mounted || confirmed != true) return;

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
          type: 'Inpunch',
          id: '0',
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

  Future<void> _logout() async {
    if (_isLoggingOut ||
        _isPreparingPunchIn ||
        context.read<DashboardBloc>().state.punchInStatus ==
            DashboardStatus.loading) {
      return;
    }
    setState(() => _isLoggingOut = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          titleTextStyle: Theme.of(dialogContext).textTheme.titleLarge
              ?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
          contentTextStyle: Theme.of(
            dialogContext,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          title: const Text('Log out?'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.buttonText,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log out'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;

      final storage = sl<SecureStorage>();
      await storage.clearPunchInResult();
      await storage.clearLoginResponse();
      if (!mounted) return;
      context.go(AppRouter.login);
    } catch (_) {
      if (mounted) _showMessage('Unable to log out. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> loadLoginInData() async {
    try {
      final loginData = await sl<SecureStorage>().readLoginResponse();

      if (!mounted) return;

      if (loginData == null ||
          !loginData.status ||
          loginData.result.isEmpty ||
          loginData.result.first.name.trim().isEmpty) {
        _showMessage('Please sign in again before clocking in.');
        return;
      }
      setState(() {
        _userName = loginData.result.first.name.trim();
      });
    } catch (e) {
      debugPrint('Error loading Login data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Theme.of(context).platform != TargetPlatform.android,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPressed = now;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
      },
      child: Scaffold(
        body: BlocConsumer<DashboardBloc, DashboardState>(
          listenWhen: (previous, current) =>
              previous.punchInStatus != current.punchInStatus,
          listener: (context, state) {
            if (state.punchInStatus == DashboardStatus.failure) {
              _showMessage(state.errorMessage);
            } else if (state.punchInStatus == DashboardStatus.success) {
              context.push(AppRouter.punchOut);
              // Navigator.of(
              //   context,
              // ).push(MaterialPageRoute(builder: (_) => const PunchOutPage()));
            }
          },
          builder: (context, state) => _buildDashboard(context, state),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardState state) {
    final isLoading =
        _isPreparingPunchIn || state.punchInStatus == DashboardStatus.loading;

    return DashboardBackground(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 650;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DashboardGreeting(
                              name: _userName,
                              dateTime: _currentTime,
                              onMe: () => context.push(AppRouter.me),
                              onLogout: _isLoggingOut || isLoading
                                  ? null
                                  : _logout,
                            ),

                            SizedBox(height: isCompact ? 65 : 112),

                            DashboardClockCard(
                              dateTime: _displayClockInTime,
                              onEdit:
                                  _selectedWorkspace == WorkspaceType.personal
                                  ? _editClockInTime
                                  : null,
                            ),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: isCompact ? 28 : 60),

                            Showcase(
                              key: _projectShowcaseKey,
                              scope: _showcaseScope,
                              title: 'Choose your project',
                              description:
                                  'Select the project you are '
                                  'working on before clocking in.',
                              targetPadding: const EdgeInsets.all(8),
                              targetBorderRadius: BorderRadius.circular(13),
                              tooltipPadding: const EdgeInsets.all(16),
                              tooltipActions: [
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.skip,
                                  name: 'OK',
                                  textStyle: const TextStyle(
                                    color: AppColors.white,
                                  ),
                                  onTap: _showcaseView.dismiss,
                                ),
                              ],
                              child: DashboardProjectCard(
                                selectedProject: _selectedProject,
                                workspaceLabel:
                                    _selectedWorkspace == WorkspaceType.personal
                                    ? 'Personal · Private'
                                    : 'Business · Shared projects',
                                onProjectSelected: _onProjectSelected,
                                onRemoveProject: () {
                                  setState(() {
                                    _selectedProject = null;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 15),

                            DashboardWorkspaceCard(
                              selectedType: _selectedWorkspace,
                              onChanged: (type) {
                                setState(() {
                                  _selectedWorkspace = type;
                                });
                              },
                            ),

                            const SizedBox(height: 12),

                            DashboardSlideButton(
                              isLoading: isLoading,
                              isClockedIn: false,
                              onCompleted: _onSlideCompleted,
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
