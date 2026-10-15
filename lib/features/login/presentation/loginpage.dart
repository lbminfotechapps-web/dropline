import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/features/otp/presentation/otp_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final FocusNode _mobileFocusNode = FocusNode();

  bool _isValid = false;
  bool _isNavigating = false;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primary = Appcolors.primaryColor;
  static const Color primaryDark = Appcolors.primaryDark;

  static const Color dark = Appcolors.backgroundColor;

  // Clean light grey background
  static const Color background = Color(0xFFF3F4F3);

  static const Color textGrey = Color(0xFF737A76);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mobileFocusNode.requestFocus();
      }
    });

    _mobileController.addListener(_onMobileChanged);
  }

  // ============================================================
  // MOBILE CHANGE
  // ============================================================

  void _onMobileChanged() {
    final value = _mobileController.text.replaceAll(' ', '');

    final valid = value.length == 10;

    if (_isValid != valid) {
      setState(() {
        _isValid = valid;
      });
    }

    if (valid && !_isNavigating) {
      _continueLogin();
    }
  }

  // ============================================================
  // CONTINUE LOGIN
  // ============================================================

  void _continueLogin() {
    if (!_isValid || _isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    FocusScope.of(context).unfocus();

    final mobileNumber = '+1${_mobileController.text.replaceAll(' ', '')}';

    debugPrint('Mobile Number: $mobileNumber');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpScreen(mobileNumber: mobileNumber),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _mobileController.removeListener(_onMobileChanged);
    _mobileController.dispose();
    _mobileFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 35),

              // ==================================================
              // TOP BRAND
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'DROPLINE-SITE',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // ==================================================
              // HERO LOGO
              // ==================================================
              Stack(
                alignment: Alignment.center,
                children: [
                  // Soft green circle
                  Container(
                    height: 112,
                    width: 112,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Logo container
                  Container(
                    height: 82,
                    width: 82,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/dropline_launcher.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ==================================================
              // TITLE
              // ==================================================
              const Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.8,
                ),
              ),

              const SizedBox(height: 9),

              const Text(
                'Manage your projects.\n'
                'Stay connected with your team.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5, color: textGrey),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // LOGIN CARD
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE4E7E5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.055),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // CARD TITLE
                    // ==================================================
                    const Text(
                      'Sign in with your mobile',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'We’ll verify your number with a one-time code.',
                      style: TextStyle(fontSize: 12.5, color: textGrey),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // PHONE FIELD
                    // ==================================================
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAF9),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: _isValid ? primary : const Color(0xFFE0E5E2),
                          width: _isValid ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 13),

                          // ==================================================
                          // FLAG
                          // ==================================================
                          Container(
                            height: 36,
                            width: 45,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE6EAE7),
                              ),
                            ),
                            child: const Text(
                              '🇺🇸',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // ==================================================
                          // COUNTRY CODE
                          // ==================================================
                          const Text(
                            '+1',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(width: 11),

                          // ==================================================
                          // DIVIDER
                          // ==================================================
                          Container(
                            height: 27,
                            width: 1,
                            color: const Color(0xFFDDE2DF),
                          ),

                          const SizedBox(width: 11),

                          // ==================================================
                          // PHONE INPUT
                          // ==================================================
                          Expanded(
                            child: TextField(
                              controller: _mobileController,
                              focusNode: _mobileFocusNode,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              maxLength: 10,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                letterSpacing: 0.4,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Phone number',
                                hintStyle: TextStyle(
                                  color: Color(0xFFA4ABA7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onSubmitted: (_) {
                                _continueLogin();
                              },
                            ),
                          ),

                          // ==================================================
                          // VALID SUCCESS ICON
                          // ==================================================
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isValid
                                ? const Padding(
                                    padding: EdgeInsets.only(right: 15),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: primaryDark,
                                      size: 24,
                                    ),
                                  )
                                : const SizedBox(width: 15),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // SECURITY INFORMATION
                    // ==================================================
                    Row(
                      children: [
                        Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: primaryDark,
                          ),
                        ),

                        const SizedBox(width: 9),

                        const Expanded(
                          child: Text(
                            'Your number is encrypted and used only '
                            'for account verification.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textGrey,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // WORKSITE LABEL
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 6,
                    width: 6,
                    decoration: const BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 7),

                  const Text(
                    'BUILT FOR THE FIELD',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: Color(0xFF8B928E),
                    ),
                  ),

                  const SizedBox(width: 7),

                  Container(
                    height: 6,
                    width: 6,
                    decoration: const BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ==================================================
              // TERMS
              // ==================================================
              Text.rich(
                TextSpan(
                  text: 'By continuing, you agree to our ',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF929894),
                  ),
                  children: [
                    const TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    const TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
