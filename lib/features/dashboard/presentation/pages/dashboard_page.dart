import 'dart:async';

import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:flutter/material.dart';
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
  String? _selectedProject;
  final bool _isClockedIn = true;

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

  void _onProjectSearch(String query) {
    final project = query.trim();
    if (_selectedProject != null || project.isEmpty) return;
    setState(() => _selectedProject = project);
  }
  // =========================================
  // CLOCK IN / CLOCK OUT
  // =========================================

  void _onSlideCompleted() {
    context.push(AppRouter.punchOut);
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       _isClockedIn
    //           ? 'Clock Out API integration pending'
    //           : 'Clock In API integration pending',
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
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
                              onSearch: _onProjectSearch,
                              onRemoveProject: () =>
                                  setState(() => _selectedProject = null),
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
                              isClockedIn: _isClockedIn,
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
