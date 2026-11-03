import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/showcase_once.dart';
import 'dart:async';

import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:dropline/core/utility/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';

import '../widgets/punch_header.dart';
import '../widgets/punch_time_card.dart';
import '../widgets/work_details_card.dart';
import '../widgets/punch_out_slide_bar.dart';

class PunchOutPage extends StatefulWidget {
  const PunchOutPage({super.key});

  @override
  State<PunchOutPage> createState() => _PunchOutPageState();
}

class _PunchOutPageState extends State<PunchOutPage>
    with WidgetsBindingObserver {
  final _workDetailsShowcaseKey = GlobalKey();
  late final String _showcaseScope;
  late final ShowcaseView _showcaseView;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  DateTime? _punchInTime;

  @override
  void initState() {
    super.initState();
    _showcaseScope = 'punch-out-${identityHashCode(this)}';
    _showcaseView = ShowcaseView.register(
      scope: _showcaseScope,
      enableAutoScroll: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseOnce.show(
        id: 'work_details',
        showcase: _showcaseView,
        target: _workDetailsShowcaseKey,
        isMounted: () => mounted,
      );
    });
    WidgetsBinding.instance.addObserver(this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTime();
    });
    loadPunchInData();
  }

  void _updateTime() {
    if (!mounted) return;
    setState(() => _currentTime = DateTime.now());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _updateTime();
  }

String get sessionDate {
  const months = [
    'January', 'February', 'March',
    'April', 'May', 'June',
    'July', 'August', 'September',
    'October', 'November', 'December',
  ];

  final date = _punchInTime ?? _currentTime;

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

  @override
  void dispose() {
    _showcaseView.unregister();
    _clockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String projectName = '';
  String inTime = '';

  bool isLoading = true;
  String get workedDuration {
    final start = _punchInTime;
    if (start == null) return '--:--';
    final elapsed = _currentTime.difference(start);
    final minutes = elapsed.isNegative ? 0 : elapsed.inMinutes;
    return '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
        '${(minutes % 60).toString().padLeft(2, '0')}';
  }

  String get clockOutTime =>
      '${_currentTime.hour.toString().padLeft(2, '0')}:'
      '${_currentTime.minute.toString().padLeft(2, '0')}';
  final String workType = 'EVENT';

  Future<void> loadPunchInData() async {
    try {
      final punchData = await sl<SecureStorage>().readPunchInResult();

      if (!mounted) return;

      // Check whether saved Punch In data exists
      if (punchData.isEmpty) {
        debugPrint('No saved Punch In data found');

        setState(() {
          isLoading = false;
        });

        return;
      }

      final punch = punchData.first;

      final time = punch.time.trim();
      // The API stores the punch-in date and time in separate fields.
      final punchInTime = DateTime.tryParse('${punch.date.trim()}T$time');
      setState(() {
        _punchInTime = punchInTime;
        _currentTime = DateTime.now();
        inTime = time.length >= 5 ? time.substring(0, 5) : time;
        projectName = punch.projectName.trim();
        isLoading = false;
      });

      debugPrint('In Time: $inTime');
      debugPrint('Project Name: $projectName');
      debugPrint('InPunch ID: ${punch.inpunchId}');
    } catch (e) {
      debugPrint('Error loading Punch In data: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _onAddWorkDetails() async {
    try {
      // Read saved Punch In result
      final punchData = await sl<SecureStorage>().readPunchInResult();

      if (!mounted) return;

      // Get first Punch In record
      final punch = punchData.first;

      // Read Project ID and Project Name
      final String selectedProjectId = punch.projectId.trim();
      final String selectedProjectName = punch.projectName.trim();

      debugPrint('Project ID: $selectedProjectId');
      debugPrint('Project Name: $selectedProjectName');
      debugPrint('InPunch ID: ${punch.inpunchId}');

      // Navigate to Add Event screen
      context.push(
        AppRouter.addEvent,
        extra: {
          'projectId': selectedProjectId,
          'projectName': selectedProjectName,
        },
      );
    } catch (e) {
      debugPrint('Read Punch In Error: $e');

      if (!mounted) return;
    }
  }

  void _onClockOut() {
    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(const SnackBar(content: Text('Clock Out action triggered')));
    AppToast.success('Clock Out action triggered.');
  }

 
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20, 14, 20, 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 38,
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          PunchHeader(
                            title: projectName.isNotEmpty
                                ? projectName
                                : 'No Project Selected',
                            workspace: 'Business',
                            onBack: () {
                              context.go(AppRouter.dashboard);
                            },
                            onMe: () {
                              context.push(AppRouter.me);
                            },
                          ),
    
                          const SizedBox(height: 26),
    
                          const Text(
                            'Work session',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
    
                          const SizedBox(height: 5),
    
                          Text(
                            sessionDate,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
    
                          const SizedBox(height: 22),
    
                          PunchWorkSessionCard(
                            workedDuration: workedDuration,
                            clockInTime: inTime.isEmpty
                                ? '--:--'
                                : inTime,
                            currentTime: clockOutTime,
                            isLoading: isLoading,
                          ),
    
                          const SizedBox(height: 24),
    
                          Showcase(
                            key: _workDetailsShowcaseKey,
                            scope: _showcaseScope,
                            title: 'Add your work details',
                            description:
                                'Tap Add event to record quality, '
                                'safety, progress and other '
                                'work details.',
                            targetPadding:
                                const EdgeInsets.all(8),
                            targetBorderRadius:
                                BorderRadius.circular(16),
                            tooltipPadding:
                                const EdgeInsets.all(16),
                            tooltipActions: [
                              TooltipActionButton(
                                type:
                                    TooltipDefaultActionType.skip,
                                name: 'OK',
                                textStyle: const TextStyle(
                                  color: AppColors.white,
                                ),
                                onTap: _showcaseView.dismiss,
                              ),
                            ],
                            disposeOnTap: true,
                            onTargetClick: _onAddWorkDetails,
                            child: WorkDetailsCard(
                              onTap: _onAddWorkDetails,
                            ),
                          ),
                        ],
                      ),
    
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 48),
    
                          PunchOutSlideBar(
                            isLoading: isLoading,
                            onCompleted: _onClockOut,
                          ),
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
