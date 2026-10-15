import 'package:dropline/features/auth/presentation/pages/loginpage.dart';
import 'package:dropline/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:dropline/features/event/presentation/add_event.dart';
import 'package:dropline/features/punch/presentation/pages/punch_out.dart';

import 'package:dropline/features/splash.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const String splash = '/splash';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String addEvent = '/add-event';
  static const String punchOut = '/punchOut';

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: splash,

    routes: [
      GoRoute(
        path: addEvent,
        name: 'addEvent',
        builder: (context, state) => const AddEventPage(),
      ),
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) {
          return const SplashScreen();
        },
      ),

      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: dashboard,
        name: 'dashboard',
        builder: (context, state) {
          return const DashboardPage();
        },
      ),

      GoRoute(
        path: punchOut,
        name: 'punchOut',
        builder: (context, state) => const PunchOutPage(),
      ),
    ],
  );
}
