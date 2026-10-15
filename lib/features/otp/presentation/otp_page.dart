import 'dart:async';

import 'package:dropline/core/theme/appcolors.dart' show Appcolors;
import 'package:dropline/features/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpScreen extends StatefulWidget {
  final String mobileNumber;

  const OtpScreen({super.key, required this.mobileNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // ============================================================
  // OTP CONTROLLERS
  // ============================================================

  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;

  int _secondsRemaining = 30;
  bool _isVerifying = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  // ============================================================
  // TIMER
  // ============================================================

  void _startTimer() {
    _timer?.cancel();

    _secondsRemaining = 30;

    if (mounted) {
      setState(() {});
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();

        setState(() {
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  // ============================================================
  // GET OTP
  // ============================================================

  String get _otp {
    return _controllers.map((controller) => controller.text).join();
  }

  // ============================================================
  // OTP CHANGE
  // ============================================================

  void _onOtpChanged(String value, int index) {
    // ==========================================================
    // HANDLE PASTED OTP
    // ==========================================================

    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

      if (digits.isEmpty) {
        return;
      }

      // Clear all boxes
      for (final controller in _controllers) {
        controller.clear();
      }

      // Fill OTP boxes
      for (int i = 0; i < digits.length && i < 6; i++) {
        _controllers[i].text = digits[i];
      }

      if (digits.length >= 6) {
        _focusNodes[5].requestFocus();

        if (mounted) {
          setState(() {});
        }

        _verifyOtp();
      } else {
        _focusNodes[digits.length].requestFocus();

        if (mounted) {
          setState(() {});
        }
      }

      return;
    }

    // ==========================================================
    // NORMAL SINGLE DIGIT ENTRY
    // ==========================================================

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    }

    if (mounted) {
      setState(() {});
    }

    // ==========================================================
    // AUTO VERIFY
    // ==========================================================

    if (_otp.length == 6) {
      _verifyOtp();
    }
  }

  // ============================================================
  // BACKSPACE
  // ============================================================

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();

      _focusNodes[index - 1].requestFocus();

      if (mounted) {
        setState(() {});
      }

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_otp.length != 6 || _isVerifying) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    FocusScope.of(context).unfocus();

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) {
      return;
    }

    setState(() {
      _isVerifying = false;
    });

    // ==========================================================
    // OTP SUCCESS → DASHBOARD
    // ==========================================================

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  void _resendOtp() {
    if (_secondsRemaining > 0 || _isVerifying) {
      return;
    }

    debugPrint('========================================');
    debugPrint('RESEND OTP');
    debugPrint('Mobile: ${widget.mobileNumber}');
    debugPrint('========================================');

    // ==========================================================
    // CALL RESEND OTP API HERE
    // ==========================================================

    for (final controller in _controllers) {
      controller.clear();
    }

    _startTimer();

    _focusNodes[0].requestFocus();

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // EDIT MOBILE NUMBER
  // ============================================================

  void _editMobileNumber() {
    Navigator.pop(context);
  }

  // ============================================================
  // FORMAT MOBILE NUMBER
  // ============================================================

  String _formatMobileNumber(String number) {
    final clean = number.replaceAll(RegExp(r'[^0-9]'), '');

    if (clean.length == 11 && clean.startsWith('1')) {
      return '+1 ${clean.substring(1, 4)} '
          '${clean.substring(4, 7)} '
          '${clean.substring(7)}';
    }

    if (clean.length == 10) {
      return '+1 ${clean.substring(0, 3)} '
          '${clean.substring(3, 6)} '
          '${clean.substring(6)}';
    }

    return number;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.backgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TOP
              // ==================================================
              const SizedBox(height: 25),

              // ==================================================
              // BACK BUTTON
              // ==================================================
              GestureDetector(
                onTap: _editMobileNumber,
                child: Container(
                  height: 44,
                  width: 44,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),

                    border: Border.all(color: const Color(0xFFE3E8E5)),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Appcolors.darkColor,
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(height: 45),

              // ==================================================
              // OTP ICON
              // ==================================================
              Center(
                child: Container(
                  height: 82,
                  width: 82,

                  decoration: BoxDecoration(
                    color: Appcolors.darkColor,
                    borderRadius: BorderRadius.circular(25),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: const Icon(
                    Icons.sms_outlined,
                    size: 40,
                    color: Appcolors.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // TITLE
              // ==================================================
              const Center(
                child: Text(
                  'Verify your number',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Appcolors.darkColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // DESCRIPTION
              // ==================================================
              const Center(
                child: Text(
                  'Enter the 6-digit code we sent to your mobile number.',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF737A76),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // MOBILE NUMBER
              // ==================================================
              Center(
                child: GestureDetector(
                  onTap: _editMobileNumber,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      color: Appcolors.primaryColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 15,
                          color: Appcolors.primaryDark,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          _formatMobileNumber(widget.mobileNumber),

                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Appcolors.primaryDark,
                          ),
                        ),

                        const SizedBox(width: 5),

                        const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Appcolors.primaryDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // OTP CARD
              // ==================================================
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(24),

                  border: Border.all(color: const Color(0xFFE5E9E6)),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    // ==========================================
                    // LABEL
                    // ==========================================
                    const Text(
                      'Verification code',

                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Appcolors.darkColor,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==========================================
                    // OTP BOXES
                    // ==========================================
                    SizedBox(
                      height: 58,

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 42,
                            height: 58,

                            child: Focus(
                              onKeyEvent: (node, event) {
                                return _handleKeyEvent(node, event, index);
                              },

                              child: TextField(
                                controller: _controllers[index],

                                focusNode: _focusNodes[index],

                                keyboardType: TextInputType.number,

                                textInputAction: index == 5
                                    ? TextInputAction.done
                                    : TextInputAction.next,

                                textAlign: TextAlign.center,

                                maxLength: 1,

                                enabled: !_isVerifying,

                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Appcolors.darkColor,
                                ),

                                decoration: InputDecoration(
                                  counterText: '',

                                  filled: true,

                                  fillColor: const Color(0xFFF8FAF9),

                                  contentPadding: EdgeInsets.zero,

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),

                                    borderSide: const BorderSide(
                                      color: Color(0xFFE1E6E3),
                                    ),
                                  ),

                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),

                                    borderSide: const BorderSide(
                                      color: Color(0xFFE1E6E3),
                                    ),
                                  ),

                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),

                                    borderSide: const BorderSide(
                                      color: Appcolors.primaryColor,
                                      width: 2,
                                    ),
                                  ),

                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),

                                    borderSide: const BorderSide(
                                      color: Color(0xFFE1E6E3),
                                    ),
                                  ),
                                ),

                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],

                                onChanged: (value) {
                                  _onOtpChanged(value, index);
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==========================================
                    // VERIFYING
                    // ==========================================
                    if (_isVerifying) ...[
                      const SizedBox(
                        height: 3,

                        child: LinearProgressIndicator(
                          minHeight: 3,

                          backgroundColor: Color(0xFFF1F3F2),

                          valueColor: AlwaysStoppedAnimation<Color>(
                            Appcolors.primaryColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Verifying code...',

                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF737A76),
                        ),
                      ),
                    ] else ...[
                      // ========================================
                      // RESEND
                      // ========================================
                      GestureDetector(
                        onTap: _resendOtp,

                        child: Text(
                          _secondsRemaining > 0
                              ? 'Resend code in ${_secondsRemaining}s'
                              : 'Resend code',

                          style: TextStyle(
                            color: _secondsRemaining > 0
                                ? const Color(0xFF8A918E)
                                : Appcolors.primaryDark,

                            fontWeight: FontWeight.w700,

                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ==================================================
              // BOTTOM SPACE
              // ==================================================
              const SizedBox(height: 70),

              // ==================================================
              // SECURITY MESSAGE
              // ==================================================
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: Color(0xFF858D89),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      'Your verification code is secure and private.',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
