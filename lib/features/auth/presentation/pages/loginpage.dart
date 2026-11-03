import 'package:dropline/core/utility/showcase_once.dart';
import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/utility/widgets/app_toast.dart';
import 'package:dropline/features/auth/presentation/bloc/login_bloc.dart';
import 'package:dropline/features/auth/presentation/bloc/login_event.dart';
import 'package:dropline/features/auth/presentation/bloc/login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:showcaseview/showcaseview.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _termsShowcaseKey = GlobalKey();
  late final ShowcaseView _showcaseView;
  late final String _showcaseScope;
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _codeControllers = List.generate(4, (_) => TextEditingController());
  final _codeFocusNodes = List.generate(4, (_) => FocusNode());
  bool _agreed = false;
  late final LoginBloc _loginBloc;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loginBloc = sl<LoginBloc>();
    _showcaseScope = 'login-${identityHashCode(this)}';
    _showcaseView = ShowcaseView.register(
      scope: _showcaseScope,
      enableAutoScroll: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseOnce.show(
        id: 'login_terms',
        showcase: _showcaseView,
        target: _termsShowcaseKey,
        isMounted: () => mounted,
      );
    });
  }

  double _slide = 0;

  Future<void> _showTermsAndConditions() async {
    FocusScope.of(context).unfocus();
    final accepted = await showAdaptiveDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final platform = Theme.of(dialogContext).platform;
        final isApple =
            platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
        final textColour = isApple
            ? CupertinoColors.label.resolveFrom(dialogContext)
            : Theme.of(dialogContext).colorScheme.onSurface;
        final content = DefaultTextStyle(
          style: AppTextStyles.bodyMedium.copyWith(color: textColour),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'DROPLINE • UNITED KINGDOM',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isApple
                      ? CupertinoColors.secondaryLabel.resolveFrom(
                          dialogContext,
                        )
                      : Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please read these terms before continuing. '
                'These are sample terms for the demo app.',
              ),
              const SizedBox(height: 20),
              for (final section in const [
                (
                  '1. Using Dropline',
                  'Use the app lawfully and responsibly. Do not misuse the '
                      'service or try to access another person’s account.',
                ),
                (
                  '2. Your account',
                  'Provide accurate details and keep your sign-in codes '
                      'private. You are responsible for activity on your account.',
                ),
                (
                  '3. Your content',
                  'Only share files and information you own or are authorised '
                      'to use. Keep a copy of important documents.',
                ),
                (
                  '4. Privacy',
                  'The final Privacy Notice will explain how personal data is '
                      'collected, used and stored. Avoid entering sensitive '
                      'personal information in this demo.',
                ),
                (
                  '5. Service availability',
                  'Demo features may change or be unavailable from time to '
                      'time. Sample data may be reset.',
                ),
                (
                  '6. Final terms',
                  'These sample terms must be replaced with the service’s '
                      'final terms and Privacy Notice before launch. They do '
                      'not limit your statutory rights.',
                ),
              ]) ...[
                Text(
                  section.$1,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColour,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(section.$2),
                const SizedBox(height: 18),
              ],
            ],
          ),
        );

        if (isApple) {
          return CupertinoAlertDialog(
            title: const Text('Terms & Conditions'),
            // CupertinoAlertDialog keeps its actions visible while its
            // content scrolls on smaller screens and with larger text.
            content: content,
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Close'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('I agree'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('Terms & Conditions'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          scrollable: true,
          content: SizedBox(width: 400, child: content),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('I agree'),
            ),
          ],
        );
      },
    );
    if (accepted == true && mounted) {
      setState(() => _agreed = true);
    }
  }

  void _continueLogin() {
    if (_isNavigating) return;
    if (_nameController.text.trim().isEmpty ||
        _mobileController.text.length != 10) {
      setState(() => _slide = 0);
      AppToast.error('Enter your name and 10-digit mobile number.');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Enter your name and 10-digit mobile number.'),
      //   ),
      // );
      return;
    }
    if (_codeControllers.any((controller) => controller.text.length != 1)) {
      setState(() => _slide = 0);
      AppToast.error('Enter the complete 4-digit OTP.');
      return;
    }
    if (!_agreed) {
      setState(() => _slide = 0);
      AppToast.error('Please agree to the Terms & Conditions to continue.');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Please agree to the Terms & Conditions to continue.'),
      //   ),
      // );
      return;
    }
    setState(() => _isNavigating = true);
    FocusScope.of(context).unfocus();
    _loginBloc.add(
      SubmitLoginEvent(
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        mobileInfo: "Motorola 50 Pro",
        otp: _codeControllers.map((controller) => controller.text).join(),
      ),
    );
  }

  @override
  void dispose() {
    _showcaseView.unregister();
    _loginBloc.close();
    _nameController.dispose();
    _mobileController.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final focusNode in _codeFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      bloc: _loginBloc,
      listener: (context, state) {
        if (state.status == LoginStatus.success) {
          AppToast.success('Signed in successfully.');
          context.go(AppRouter.dashboard);
        } else if (state.status == LoginStatus.failure) {
          setState(() {
            _isNavigating = false;
          });
          AppToast.error(state.message);
        }
      },
      child: AbsorbPointer(
        absorbing: _isNavigating,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: AppColors.transparent,
            systemNavigationBarColor: AppColors.background,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: AppColors.background,
            resizeToAvoidBottomInset: true,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLogo(),

                            const SizedBox(height: 56),

                            const Text(
                              'Sign in',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                              ),
                            ),

                            const SizedBox(height: 5),

                            const Text(
                              'Enter your details to continue.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 30),

                            _buildLabel('Full name'),

                            const SizedBox(height: 9),

                            _buildInputField(
                              controller: _nameController,
                              hint: 'Your name',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                            ),

                            const SizedBox(height: 20),

                            _buildLabel('Mobile number'),

                            const SizedBox(height: 9),

                            _buildInputField(
                              controller: _mobileController,
                              hint: 'Your mobile number',
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              isMobile: true,
                            ),

                            const SizedBox(height: 22),

                            _buildLabel('4-digit PIN'),

                            const SizedBox(height: 9),

                            _buildPinFields(),

                            const SizedBox(height: 22),

                            _buildTermsCheckbox(),

                            const SizedBox(height: 24),

                            _buildSignInButton(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // LOGO
  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Dropline',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const Text(
          '•',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          'Site',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }

  // LABEL
  Widget _buildLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // NAME AND MOBILE INPUT
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    bool isMobile = false,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 49,
            child: Icon(icon, color: AppColors.textSecondary, size: 21),
          ),

          Container(height: 25, width: 1, color: AppColors.border),

          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textCapitalization: isMobile
                  ? TextCapitalization.none
                  : TextCapitalization.words,
              textInputAction: TextInputAction.next,
              inputFormatters: isMobile
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ]
                  : null,
              onChanged: isMobile
                  ? (value) {
                      for (final pin in _codeControllers) {
                        pin.clear();
                      }
                      if (value.length == 10) {
                        FocusScope.of(context).unfocus();
                      }
                    }
                  : null,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.hintText,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FOUR PIN BOXES
  Widget _buildPinFields() {
    return Row(
      children: [
        for (var index = 0; index < 4; index++) ...[
          if (index > 0) const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _codeControllers[index],
                focusNode: _codeFocusNodes[index],
                keyboardType: TextInputType.number,
                textInputAction: index == 3
                    ? TextInputAction.done
                    : TextInputAction.next,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                obscureText: true,
                obscuringCharacter: '•',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                cursorColor: AppColors.primary,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 3) {
                    _codeFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _codeFocusNodes[index - 1].requestFocus();
                  } else if (value.isNotEmpty && index == 3) {
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  // TERMS AND CONDITIONS
  Widget _buildTermsCheckbox() {
    return Showcase(
      key: _termsShowcaseKey,
      scope: _showcaseScope,
      title: 'Review before you sign in',
      description: 'Read the Terms & Conditions and agree before signing in.',
      targetPadding: const EdgeInsets.all(8),
      targetBorderRadius: BorderRadius.circular(12),
      tooltipPadding: const EdgeInsets.all(16),
      tooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: 'OK',
          textStyle: const TextStyle(color: AppColors.white),
          onTap: _showcaseView.dismiss,
        ),
      ],
      disposeOnTap: true,
      onTargetClick: _showTermsAndConditions,
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _agreed = !_agreed;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 23,
              width: 23,
              decoration: BoxDecoration(
                color: _agreed ? AppColors.primary : AppColors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: _agreed
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.primaryText,
                      size: 17,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 10),

          const Text(
            'I agree to the',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),

          const SizedBox(width: 4),

          Flexible(
            child: InkWell(
              onTap: _showTermsAndConditions,
              child: const Text(
                'Terms & Conditions',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SIGN IN BUTTON
  Widget _buildSignInButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isNavigating ? null : _continueLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryText,
          disabledBackgroundColor: AppColors.disabledButton,
          disabledForegroundColor: AppColors.disabledText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isNavigating
            ? const SizedBox(
                height: 23,
                width: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryText,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign in',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, size: 21),
                ],
              ),
      ),
    );
  }
}
