import 'dart:async';

import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:flutter/material.dart';

import '../widgets/dashboard_background.dart';
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
  bool _isClockedIn = true;

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

  void _onSelectProject() {
    // TODO: Open project selection using Project BLoC/API.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project selection will be connected next.'),
      ),
    );
  }

  // =========================================
  // CLOCK IN / CLOCK OUT
  // =========================================

  void _onSlideCompleted() {


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isClockedIn
              ? 'Clock Out API integration pending'
              : 'Clock In API integration pending',
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Greeting
                          DashboardGreeting(
                            name: _userName,
                            dateTime: _currentTime,
                          ),

                          const SizedBox(height: 76),

                        
                          DashboardDateCard(date: _currentTime),

                          const SizedBox(height: 38),

                        
                          DashboardProjectCard(
                            selectedProject: _selectedProject,
                            onTap: _onSelectProject,
                          ),

                          const SizedBox(height: 48),

                        
                          DashboardClockCard(dateTime: _currentTime),

                          const Spacer(),

                          const SizedBox(height: 55),

                       
                          DashboardSlideButton(
                            isClockedIn: _isClockedIn,
                            onCompleted: _onSlideCompleted,
                          ),

                          const SizedBox(height: 18),
                        ],
                      ),
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
