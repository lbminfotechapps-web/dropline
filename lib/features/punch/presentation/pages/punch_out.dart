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
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / 739;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      54 * scale,
                      48 * scale,
                      54 * scale,
                      30 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PunchHeader(
                              title: projectName.isNotEmpty
                                  ? projectName
                                  : 'No Project Selected',
                              scale: scale,
                              // onBack: () => Navigator.pop(context),
                              onBack: () => context.push(AppRouter.dashboard),
                            ),

                            SizedBox(height: 121 * scale),

                            PunchTimeCard(
                              time: inTime.isNotEmpty ? inTime : '--:--',
                              height: 200 * scale,
                              fontSize: 116 * scale,
                              radius: 54 * scale,
                            ),
                            SizedBox(height: 76 * scale),

                            PunchTimeCard(
                              time: workedDuration,
                              height: 260 * scale,
                              fontSize: 164 * scale,
                              radius: 52 * scale,
                            ),

                            SizedBox(height: 78 * scale),

                            Showcase(
                              key: _workDetailsShowcaseKey,
                              scope: _showcaseScope,
                              title: 'Add your work details',
                              description:
                                  'Tap Event to record details of the work '
                                  'you’ve done on this project.',
                              targetPadding: const EdgeInsets.all(8),
                              targetBorderRadius: BorderRadius.circular(
                                88 * scale,
                              ),
                              tooltipPadding: const EdgeInsets.all(16),
                              tooltipActions: [
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.skip,
                                  name: 'OK',
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  onTap: _showcaseView.dismiss,
                                ),
                              ],
                              disposeOnTap: true,
                              onTargetClick: _onAddWorkDetails,
                              child: WorkDetailsCard(
                                title: 'ADD WORK DETAILS',
                                value: workType,
                                onTap: _onAddWorkDetails,
                                scale: scale,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 80 * scale),
                          child: PunchOutSlideBar(
                            actionText: 'CLOCK OUT',
                            timeText: clockOutTime,
                            onCompleted: _onClockOut,
                            scale: scale,
                          ),
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
