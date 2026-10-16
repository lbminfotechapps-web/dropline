import 'dart:async';

import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    _navigationTimer = Timer(const Duration(seconds: 2), _navigate);
  }

  Future<void> _navigate() async {
    String destination = AppRouter.login;

    try {
      final secureStorage = sl<SecureStorage>();

      // ==========================================
      // STEP 1: CHECK LOGIN USER ID
      // ==========================================

      final loginResponse = await secureStorage.readLoginResponse();

      final String userId =
          loginResponse != null && loginResponse.result.isNotEmpty
          ? loginResponse.result.first.userId.trim()
          : '';

      debugPrint('Splash User ID: $userId');

      // ==========================================
      // STEP 2: CHECK USER LOGIN STATUS
      // ==========================================

      if (userId.isNotEmpty) {
        // Default navigation for logged-in user
        destination = AppRouter.dashboard;

        // ==========================================
        // STEP 3: READ SAVED PUNCH IN RESULT
        // ==========================================

        final punchResult = await secureStorage.readPunchInResult();

        if (punchResult.isNotEmpty) {
          final punch = punchResult.first;

          final String punchStatus = punch.status.trim();

          debugPrint('Splash Punch ID: ${punch.inpunchId}');
          debugPrint('Splash Punch Status: $punchStatus');
          debugPrint('Splash Project ID: ${punch.projectId}');
          debugPrint('Splash Project Name: ${punch.projectName}');

          // ==========================================
          // STEP 4: NAVIGATE BASED ON PUNCH STATUS
          // ==========================================

          // Verify the punch belongs to logged-in user
          if (punch.userId.trim() == userId) {
            if (punchStatus == '1') {
              // User already punched in
              destination = AppRouter.punchOut;
            } else if (punchStatus == '0') {
              // User not punched in
              destination = AppRouter.dashboard;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Splash navigation error: $e');

      // On error, navigate to login
      destination = AppRouter.login;
    }

    if (!mounted) return;

    debugPrint('Splash Navigate To: $destination');

    context.go(destination);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/images/glow.png', fit: BoxFit.contain),
                Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
