import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/utility/showcase_once.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'dart:async';
import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:dio/dio.dart';
import 'package:dropline/features/dashboard/data/datasource/qr_login_datasource.dart';

import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';

import '../widgets/dashboard_project_card.dart';
import '../widgets/dashboard_slide_button.dart';
import 'qr_scanner_page.dart';

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
  bool _projectValidationAttempted = false;

  bool get _isPersonalProject => _selectedProject?.typeLabel != 'Business';

  DateTime? _editedClockInTime;

  DateTime get _displayClockInTime => _editedClockInTime ?? _currentTime;
  ProjectEntity? _selectedProject;
  bool _isPreparingPunchIn = false;
  bool _isLoggingOut = false;
  bool _isApprovingQrLogin = false;

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

      setState(() => _currentTime = now);
    });

    loadLoginInData();
  }

  Future<void> _editClockInTime() async {
    final initialTime = _displayClockInTime;
    var selectedHour = initialTime.hour;
    var selectedMinute = initialTime.minute;
    final hourController = FixedExtentScrollController(
      initialItem: selectedHour,
    );
    final minuteController = FixedExtentScrollController(
      initialItem: selectedMinute,
    );
    TimeOfDay? selectedTime;
    try {
      selectedTime = await showDialog<TimeOfDay>(
        context: context,
        builder: (dialogContext) {
          Widget numberWheel({
            required FixedExtentScrollController controller,
            required int count,
            required ValueChanged<int> onChanged,
          }) => Expanded(
            child: Container(
              height: 112,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: context.surfaceColor(AppColors.inputBackground),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 32,
                diameterRatio: 2,
                useMagnifier: true,
                magnification: 1.1,
                overAndUnderCenterOpacity: 0.6,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildLoopingListDelegate(
                  children: List.generate(
                    count,
                    (value) => Center(
                      child: Text(
                        value.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 22,
                          color: context.foregroundColor(AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          return AlertDialog(
            backgroundColor: context.surfaceColor(AppColors.surface),
            title: Text(
              'Select Time',
              style: TextStyle(
                fontSize: 16,
                color: context.foregroundColor(AppColors.textPrimary),
              ),
            ),
            content: SizedBox(
              width: 264,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      numberWheel(
                        controller: hourController,
                        count: 24,
                        onChanged: (value) => selectedHour = value,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 28,
                            color: context.foregroundColor(
                              AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      numberWheel(
                        controller: minuteController,
                        count: 60,
                        onChanged: (value) => selectedMinute = value,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Expanded(child: Center(child: Text('Hour'))),
                      SizedBox(width: 36),
                      Expanded(child: Center(child: Text('Minute'))),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  TimeOfDay(hour: selectedHour, minute: selectedMinute),
                ),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      hourController.dispose();
      minuteController.dispose();
    }

    final confirmedTime = selectedTime;
    if (!mounted || confirmedTime == null) return;

    setState(() {
      _editedClockInTime = DateTime(
        initialTime.year,
        initialTime.month,
        initialTime.day,
        confirmedTime.hour,
        confirmedTime.minute,
      );
    });
  }

  Future<void> _openQrScanner() async {
    if (_isApprovingQrLogin) return;
    setState(() => _isApprovingQrLogin = true);
    try {
      final login = await sl<SecureStorage>().readLoginResponse();
      if (!mounted) return;
      if (login == null ||
          !login.status ||
          login.result.isEmpty ||
          login.result.first.userId.trim().isEmpty ||
          login.result.first.mobileNo.trim().isEmpty) {
        _showMessage('Please sign in again before approving QR login.');
        return;
      }
      final result = await Navigator.of(
        context,
      ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerPage()));
      if (!mounted || result == null || result.trim().isEmpty) return;
      final user = login.result.first;
      final message = await QrLoginDatasource(
        sl<Dio>(),
      ).approve(loginId: user.userId, mobileNo: user.mobileNo, token: result);
      if (mounted) _showMessage(message);
    } on DioException catch (error) {
      if (mounted) {
        final statusCode = error.response?.statusCode;
        final timedOut =
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout;
        _showMessage(
          statusCode != null
              ? 'QR login request failed (HTTP $statusCode). Please try again.'
              : timedOut
              ? 'QR login request timed out. Please try again.'
              : 'Cannot connect to ${error.requestOptions.uri.host}. Check that your phone is on the server’s network.',
        );
      }
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to approve QR login. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isApprovingQrLogin = false);
    }
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
      if (project.typeLabel == 'Business') _editedClockInTime = null;
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
      setState(() => _projectValidationAttempted = true);
      return;
    }

    setState(() => _isPreparingPunchIn = true);
    try {
      // final confirmed = await showDialog<bool>(
      //   context: context,
      //   builder: (dialogContext) => ClockInConfirmationDialog(
      //     workspace: project.typeLabel,
      //     projectName: project.projectName,
      //     clockInTime: _displayClockInTime,
      //   ),
      // );
      // if (!mounted || confirmed != true) return;

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
          backgroundColor: context.surfaceColor(AppColors.cardBackground),
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: context.borderColor(AppColors.cardBorder)),
          ),
          titleTextStyle: Theme.of(dialogContext).textTheme.titleLarge
              ?.copyWith(
                color: context.foregroundColor(AppColors.textPrimary),
                fontWeight: FontWeight.w500,
              ),
          contentTextStyle: Theme.of(dialogContext).textTheme.bodyMedium
              ?.copyWith(color: context.mutedColor(AppColors.textSecondary)),
          title: const Text('Log out?'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: context.mutedColor(AppColors.textSecondary),
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
    final themeController = context.read<AppThemeController?>();
    return PopScope(
      canPop: Theme.of(context).platform != TargetPlatform.android,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2))
             {
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
        backgroundColor: context.backgroundColor(AppColors.background),
        appBar: CustomAppBar(
          title: 'Clock in',
          showBackButton: false,
          actions: [
            if (themeController != null)
              Tooltip(
                message: 'White theme',
                child: Switch(
                  value: WhiteAppTheme.isEnabled(context),
                  onChanged: themeController.setWhiteTheme,
                ),
              ),
            IconButton(
              tooltip: 'Log out',
              onPressed: _isLoggingOut ? null : _logout,
              icon: Icon(
                Icons.logout_outlined,
                color: context.mutedColor(const Color(0xFFADC6D9)),
              ),
            ),
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                final isLoading =
                    _isPreparingPunchIn ||
                    state.punchInStatus == DashboardStatus.loading;
                return IconButton(
                  tooltip: 'Scan QR code',
                  onPressed: isLoading || _isLoggingOut || _isApprovingQrLogin
                      ? null
                      : _openQrScanner,
                  icon: _isApprovingQrLogin
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code_scanner),
                  color: context.mutedColor(const Color(0xFFADC6D9)),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<DashboardBloc, DashboardState>(
          listenWhen: (previous, current) =>
              previous.punchInStatus != current.punchInStatus,
          listener: (context, state) async {
            if (state.punchInStatus == DashboardStatus.failure) {
              _showMessage(state.errorMessage);
            } else if (state.punchInStatus == DashboardStatus.success) {
              await context.push(
                AppRouter.addEvent,
                extra: {
                  'projectId': _selectedProject?.projectId,
                  'projectName': _selectedProject?.projectName,
                },
              );
              if (!context.mounted) return;
              context.push(AppRouter.punchOut);
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
    final time = _displayClockInTime;
    String two(int value) => value.toString().padLeft(2, '0');
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 390 || constraints.maxHeight < 650;
          final verticalPadding = compact ? 16.0 : 24.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  verticalPadding,
                  16,
                  verticalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - verticalPadding * 2)
                        .clamp(0.0, double.infinity),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),
                        Text(
                          'Clock-in time',
                          textAlign: TextAlign.center,
                          style: context
                              .themedText(AppTextStyles.bodyMedium)
                              .copyWith(
                                color: context.mutedColor(
                                  const Color(0xFFADC6D9),
                                ),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${two(time.hour)}:${two(time.minute)}',
                                    style: context
                                        .themedText(AppTextStyles.displayMedium)
                                        .copyWith(
                                          fontSize: compact ? 44 : 56,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  TextSpan(
                                    text: ':${two(time.second)}',
                                    style: context
                                        .themedText(AppTextStyles.displaySmall)
                                        .copyWith(
                                          fontSize: compact ? 26 : 30,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                              style: context
                                  .themedText(AppTextStyles.displayMedium)
                                  .copyWith(
                                    color: context.foregroundColor(
                                      const Color(0xFFF8FAFC),
                                    ),
                                    height: 1.1,
                                  ),
                            ),
                          ),
                        ),
                        Center(
                          child: TextButton.icon(
                            onPressed: _isPersonalProject
                                ? _editClockInTime
                                : null,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: context.mutedColor(
                                Color(0xFFADC6D9),
                              ),
                              textStyle: context.themedText(
                                AppTextStyles.labelMedium,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 5),
                        Showcase(
                          key: _projectShowcaseKey,
                          scope: _showcaseScope,
                          title: 'Choose your project',
                          description:
                              'Select the project you are working on before clocking in.',
                          child: DashboardProjectCard(
                            selectedProject: _selectedProject,
                            showError:
                                _projectValidationAttempted &&
                                _selectedProject == null,
                            onProjectSelected: _onProjectSelected,
                            onRemoveProject: () =>
                                setState(() => _selectedProject = null),
                          ),
                        ),
                        SizedBox(height: compact ? 20 : 28),
                        DashboardSlideButton(
                          isLoading: isLoading,
                          isClockedIn: false,
                          onCompleted: _onSlideCompleted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
