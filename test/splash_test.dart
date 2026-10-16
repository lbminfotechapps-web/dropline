import 'dart:convert';

import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final cases = <String, String?>{
    'saved user': jsonEncode({
      'status': true,
      'result': [
        {'fld_user_id': '123'},
      ],
    }),
    'empty user ID': jsonEncode({
      'result': [
        {'fld_user_id': '  '},
      ],
    }),
    'empty result': jsonEncode({'result': []}),
    'no saved login': null,
    'invalid saved login': 'invalid json',
  };

  for (final entry in cases.entries) {
    testWidgets('Splash routes correctly with ${entry.key}', (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        if (entry.value != null) SecureStorage.loginResponseKey: entry.value!,
      });
      sl.registerSingleton<SecureStorage>(
        SecureStorage(const FlutterSecureStorage()),
      );
      addTearDown(() => sl.reset());
      final router = GoRouter(
        initialLocation: AppRouter.splash,
        routes: [
          GoRoute(
            path: AppRouter.splash,
            builder: (_, _) => const SplashScreen(),
          ),
          for (final path in [AppRouter.login, AppRouter.dashboard])
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(body: Text(path)),
            ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(
        find.text(
          entry.key == 'saved user' ? AppRouter.dashboard : AppRouter.login,
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
