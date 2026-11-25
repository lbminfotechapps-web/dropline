import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/showcase_once.dart';
import 'dart:async';
import 'dart:io';

import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/core/utility/widgets/app_toast.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:dropline/features/event/data/repositories/event_draft_store.dart';
import '../widgets/punch_event_records.dart';
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
  final _draftStore = EventDraftStore();
  List<EventDraftRecord> _records = [];
  String? _recordsError;
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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
  bool _isClockingOut = false;
  String get workedDuration {
    final start = _punchInTime;
    if (start == null) return '--:--:--';
    final elapsed = _currentTime.difference(start);
    final seconds = elapsed.isNegative ? 0 : elapsed.inSeconds;
    return '${(seconds ~/ 3600).toString().padLeft(2, '0')}:'
        '${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  String get clockOutTime =>
      '${_currentTime.hour.toString().padLeft(2, '0')}:'
      '${_currentTime.minute.toString().padLeft(2, '0')}:'
      '${_currentTime.second.toString().padLeft(2, '0')}';
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
        inTime = punchInTime == null
            ? time
            : '${punchInTime.hour.toString().padLeft(2, '0')}:'
                  '${punchInTime.minute.toString().padLeft(2, '0')}:'
                  '${punchInTime.second.toString().padLeft(2, '0')}';
        projectName = punch.projectName.trim();
        isLoading = false;
      });

      await _loadRecords();

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

  Future<void> _loadRecords() async {
    try {
      final login = await sl<SecureStorage>().readLoginResponse();
      final userId = login != null && login.result.isNotEmpty
          ? login.result.first.userId
          : 'local';
      final records = await _draftStore.records(
        userId: userId,
        project: projectName,
      );
      if (!mounted) return;
      setState(() {
        _records = records;
        _recordsError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _recordsError = 'Unable to load saved events.');
      }
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
      await context.push(
        AppRouter.addEvent,
        extra: {
          'projectId': selectedProjectId,
          'projectName': selectedProjectName,
        },
      );
      if (mounted) await _loadRecords();
    } catch (e) {
      debugPrint('Read Punch In Error: $e');

      if (!mounted) return;
    }
  }

  Future<void> _onClockOut() async {
    if (isLoading || _isClockingOut) return;
    setState(() => _isClockingOut = true);

    try {
      final documents = await getApplicationDocumentsDirectory();
      for (final name in ['event_drafts', 'event_location_drafts']) {
        final directory = Directory('${documents.path}/$name');
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }

      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.clear()) {
        throw StateError('Unable to clear local preferences');
      }
      await sl<SecureStorage>().clearAll();

      if (!mounted) return;
      context.go(AppRouter.dashboard);
      AppToast.success('Clocked out successfully.');
    } catch (error) {
      debugPrint('Error clocking out: $error');
      if (mounted) {
        AppToast.error('Unable to clock out. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isClockingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep device font preferences within the limits of this compact layout.
    // Apply this to the whole page, including event cards and the slide button.
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.1,
      child: _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor(AppColors.background),
      appBar: CustomAppBar(
        title: projectName.isEmpty ? 'No Project Selected' : projectName,
        showBackButton: false,
        titleIcon: const Icon(
          Icons.shopping_bag_outlined,
          color: Color(0xFFADC6D9),
          size: 22,
        ),
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Clocked in',
                          style: TextStyle(color: context.foregroundColor(Colors.white), fontSize: 16),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.circle,
                          color: context.accentColor(AppColors.primary),
                          size: 11,
                        ),
                        const Spacer(),
                        Text(
                          'Started ${inTime.isEmpty ? '--:--' : inTime.split(':').take(2).join(':')}',
                          style: TextStyle(
                            color: context.mutedColor(AppColors.textSecondary),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: workedDuration.substring(
                                          0,
                                          workedDuration.lastIndexOf(':'),
                                        ),
                                      ),
                                      TextSpan(
                                        text: workedDuration.substring(
                                          workedDuration.lastIndexOf(':'),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    color: context.foregroundColor(
                                      Colors.white,
                                    ),
                                    fontSize: 42,
                                    fontWeight: FontWeight.w500,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Time worked · hrs:min:sec',
                                style: TextStyle(
                                  color: context.mutedColor(
                                    AppColors.textSecondary,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Showcase(
                          key: _workDetailsShowcaseKey,
                          scope: _showcaseScope,
                          title: 'Add your work details',
                          description:
                              'Tap Add More to record photos, notes, audio and PDFs.',
                          disposeOnTap: true,
                          onTargetClick: _onAddWorkDetails,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton(
                                onPressed: isLoading || _isClockingOut
                                    ? null
                                    : _onAddWorkDetails,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.primaryText,
                                  minimumSize: const Size(150, 60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Add More',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Text(
                                      'PDF, Note, Photo, Audio',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_recordsError != null)
                      TextButton(
                        onPressed: _loadRecords,
                        child: Text('$_recordsError Tap to retry.'),
                      ),
                    PunchEventRecords(records: _records),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: PunchOutSlideBar(
                isLoading: isLoading || _isClockingOut,
                onCompleted: _onClockOut,
              ),
            ),
            SizedBox(
              height: 58,
              child: Row(
                children: [
                  _navigationTab(
                    'Dashboard',
                    Icons.dashboard_rounded,
                    AppRouter.dashboard,
                    true,
                  ),
                  _navigationTab(
                    'Workspace',
                    Icons.scatter_plot_outlined,
                    AppRouter.me,
                    false,
                  ),
                  _navigationTab(
                    'Records',
                    Icons.folder_outlined,
                    AppRouter.myUpdates,
                    false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigationTab(
    String label,
    IconData icon,
    String route,
    bool selected,
  ) {
    final color = selected
        ? context.accentColor(AppColors.primary)
        : context.mutedColor(const Color(0xFFADC6D9));
    return Expanded(
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
