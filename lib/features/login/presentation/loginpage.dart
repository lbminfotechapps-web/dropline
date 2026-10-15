import 'dart:math' as math;

import 'package:dropline/features/otp/presentation/otp_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

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

  Future<void> _continueLogin() async {
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(mobileNumber: '+1${_mobileController.text}'),
      ),
    );
    if (mounted) {
      setState(() {
        _isNavigating = false;
        _slide = 0;
      });
    }
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
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF4B5869),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final s = w / 591;
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
                keyboardType: phone ? TextInputType.phone : TextInputType.name,
                textCapitalization: phone
                    ? TextCapitalization.none
                    : TextCapitalization.words,
                style: TextStyle(color: Colors.white, fontSize: 27 * s),
                cursorColor: Colors.white,
                inputFormatters: phone
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ]
                    : null,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: const Color(0xFFCDD2D8),
                    fontSize: 27 * s,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: false,
                  contentPadding: EdgeInsets.only(bottom: 30 * s),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF8A94A2)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              );
            }

            return Stack(
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
                    style: TextStyle(
                      color: Colors.white,
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
                for (var i = 0; i < 4; i++)
                  place(
                    51 + i * 123,
                    803,
                    86,
                    108,
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.025),
                        borderRadius: BorderRadius.circular(32 * s),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 1.5 * s,
                        ),
                      ),
                      child: TextField(
                        controller: _codeControllers[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48 * s,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: ['2', '3', '5', '1'][i],
                          hintStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 48 * s,
                            fontWeight: FontWeight.w700,
                          ),
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
                                  ? const Color(0xFF82FF27)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10 * s),
                              border: Border.all(
                                color: const Color(0xFF82FF27),
                              ),
                            ),
                            child: _agreed
                                ? Icon(
                                    Icons.check_rounded,
                                    color: const Color(0xFF233D22),
                                    size: 25 * s,
                                  )
                                : null,
                          ),
                        ),
                        SizedBox(width: 17 * s),
                        Text(
                          'I agree to the',
                          style: TextStyle(
                            color: const Color(0xFFD1D6DF),
                            fontSize: 20 * s,
                          ),
                        ),
                        SizedBox(width: 18 * s),
                        Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            color: const Color(0xFF49C4E5),
                            fontSize: 20 * s,
                            fontWeight: FontWeight.w600,
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
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60 * s),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF496A91), Color(0xFF4D5C6C)],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1.5 * s,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFDFD6A3,
                              ).withValues(alpha: 0.1),
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
                                style: TextStyle(
                                  color: Colors.white,
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
                                          (_slide + details.delta.dx / travel)
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
                                    color: const Color(0xFF5B6B7C),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5 * s,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFB9DEEE,
                                        ).withValues(alpha: 0.25),
                                        blurRadius: 15 * s,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.keyboard_double_arrow_right,
                                    color: Colors.white,
                                    size: 40 * s,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
