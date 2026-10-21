import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

/// Keeps each onboarding hint separate and persists across app launches.
class ShowcaseOnce {
  ShowcaseOnce._();

  static Future<void> show({
    required String id,
    required ShowcaseView showcase,
    required GlobalKey target,
    required bool Function() isMounted,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final key = 'showcase_seen_$id';
      if (!isMounted() || preferences.getBool(key) == true) return;

      final context = target.currentContext;
      if (context == null || !context.mounted) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;

      showcase.startShowCase([target]);
      await preferences.setBool(key, true);
    } catch (error) {
      // A missing preference store must not prevent using the screen.
      debugPrint('Unable to save showcase progress: $error');
    }
  }
}
