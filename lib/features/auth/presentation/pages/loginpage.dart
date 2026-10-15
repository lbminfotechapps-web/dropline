import 'dart:math' as math;
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _codeControllers = List.generate(4, (_) => TextEditingController());
  bool _agreed = true;
  bool _isNavigating = false;
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
        _mobileController.text.length != 10 ||
        !_agreed) {
      setState(() => _slide = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter your name and 10-digit mobile number, and agree to the terms.',
          ),
        ),
      );
      return;
    }
    _isNavigating = true;
    FocusScope.of(context).unfocus();
    context.go(AppRouter.dashboard);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
        systemNavigationBarColor: AppColors.loginNavigationBar,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final s = w / 591;
            // Keep the design proportions on short screens and when the
            // keyboard reduces the viewport; the scroll view handles the rest.
            final h = math.max(
              constraints.maxHeight + MediaQuery.viewInsetsOf(context).bottom,
              1280 * s,
            );
            Widget place(
              double x,
              double y,
              double width,
              double height,
              Widget child,
            ) {
              return Positioned(
                left: x * s,
                top: y / 1280 * h,
                width: width * s,
                height: height / 1280 * h,
                child: child,
              );
            }

            Widget field(
              String hint,
              TextEditingController controller, {
              bool phone = false,
            }) {
              return TextField(
                controller: controller,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                onChanged: phone
                    ? (value) {
                        setState(() {
                          for (final codeController in _codeControllers) {
                            codeController.clear();
                          }
                        });
                        if (value.length == 10) {
                          FocusScope.of(context).unfocus();
                        }
                      }
                    : null,
                keyboardType: phone ? TextInputType.phone : TextInputType.name,
                textCapitalization: phone
                    ? TextCapitalization.none
                    : TextCapitalization.words,
                style: AppTextStyles.inputText.copyWith(fontSize: 27 * s),
                cursorColor: AppColors.white,
                inputFormatters: phone
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ]
                    : null,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.inputHint.copyWith(
                    color: AppColors.loginHint,
                    fontSize: 27 * s,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: false,
                  contentPadding: EdgeInsets.only(bottom: 30 * s),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.loginInputBorder),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom > 0
                    ? MediaQuery.paddingOf(context).bottom + 24
                    : 0,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/images/splash.png', fit: BoxFit.fill),
                    place(
                      (591 - 360) / 2,
                      168,
                      360,
                      47,
                      Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    place(
                      43,
                      423,
                      505,
                      49,
                      Text(
                        'Sign in',
                        style: AppTextStyles.displaySmall.copyWith(
                          fontSize: 36 * s,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2 * s,
                        ),
                      ),
                    ),
                    place(43, 522, 505, 67, field('Name', _nameController)),
                    place(
                      43,
                      642,
                      505,
                      67,
                      field('Mobile', _mobileController, phone: true),
                    ),
                    for (
                      var i = 0;
                      i < (_mobileController.text.length == 10 ? 4 : 0);
                      i++
                    )
                      place(
                        51 + i * 123,
                        803,
                        86,
                        108,
                        Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.025),
                            borderRadius: BorderRadius.circular(32 * s),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.16),
                              width: 1.5 * s,
                            ),
                          ),
                          child: TextField(
                            controller: _codeControllers[i],
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.center,
                            cursorColor: AppColors.white,
                            scrollPadding: EdgeInsets.fromLTRB(
                              32,
                              32,
                              32,
                              h * (1280 - 803 - 108) / 1280 + 24,
                            ),
                            textInputAction: i < 3
                                ? TextInputAction.next
                                : TextInputAction.done,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            style: AppTextStyles.displayMedium.copyWith(
                              height: 1,
                              fontSize: 48 * s,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isCollapsed: true,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && i < 3) {
                                FocusScope.of(context).nextFocus();
                              }
                            },
                          ),
                        ),
                      ),
                    place(
                      97,
                      1067,
                      384,
                      36,
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _agreed = !_agreed),
                              child: Container(
                                width: 34 * s,
                                height: 34 * s,
                                decoration: BoxDecoration(
                                  color: _agreed
                                      ? AppColors.loginAgreement
                                      : AppColors.transparent,
                                  borderRadius: BorderRadius.circular(10 * s),
                                  border: Border.all(
                                    color: AppColors.loginAgreement,
                                  ),
                                ),
                                child: _agreed
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: AppColors.loginAgreementIcon,
                                        size: 25 * s,
                                      )
                                    : null,
                              ),
                            ),
                            SizedBox(width: 17 * s),
                            Text(
                              'I agree to the',
                              style: AppTextStyles.inputText.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 20 * s,
                              ),
                            ),
                            SizedBox(width: 18 * s),
                            InkWell(
                              onTap: _showTermsAndConditions,
                              child: Text(
                                'Terms & Conditions',
                                style: AppTextStyles.link.copyWith(
                                  color: AppColors.loginLink,
                                  fontSize: 20 * s,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.loginLink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    place(
                      43,
                      1124,
                      505,
                      98,
                      LayoutBuilder(
                        builder: (context, sliderConstraints) {
                          final knobSize = math.min(
                            80 * s,
                            sliderConstraints.maxHeight - 16 * s,
                          );
                          final travel = math.max(
                            0.0,
                            sliderConstraints.maxWidth - knobSize - 34 * s,
                          );
                          return GestureDetector(
                            onTap: _continueLogin,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(60 * s),
                                gradient: AppColors.loginButtonGradient,
                                border: Border.all(
                                  color: AppColors.white.withValues(
                                    alpha: 0.18,
                                  ),
                                  width: 1.5 * s,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.loginButtonGlow.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 10 * s,
                                    offset: Offset(0, 3 * s),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    left: 160 * s,
                                    child: Text(
                                      'SLIDE TO SIGN IN',
                                      style: AppTextStyles.buttonLarge.copyWith(
                                        fontSize: 28 * s,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6 * s,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 16 * s + _slide * travel,
                                    child: GestureDetector(
                                      onHorizontalDragUpdate: (details) {
                                        if (travel > 0) {
                                          setState(
                                            () => _slide =
                                                (_slide +
                                                        details.delta.dx /
                                                            travel)
                                                    .clamp(0.0, 1.0),
                                          );
                                        }
                                      },
                                      onHorizontalDragEnd: (_) {
                                        if (_slide >= 0.85) {
                                          _continueLogin();
                                        } else {
                                          setState(() => _slide = 0);
                                        }
                                      },
                                      child: Container(
                                        width: knobSize,
                                        height: knobSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.loginSliderKnob,
                                          border: Border.all(
                                            color: AppColors.white,
                                            width: 1.5 * s,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.loginKnobGlow
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 15 * s,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.keyboard_double_arrow_right,
                                          color: AppColors.white,
                                          size: 40 * s,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
