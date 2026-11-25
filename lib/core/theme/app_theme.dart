import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController {
  AppThemeController() {
    _load();
  }

  static const _preferenceKey = 'white_theme_enabled';
  final _whiteTheme = ValueNotifier(false);
  ValueListenable<bool> get whiteTheme => _whiteTheme;

  bool _changed = false;

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!_changed) {
        _whiteTheme.value = preferences.getBool(_preferenceKey) ?? false;
      }
    } catch (error) {
      debugPrint('Could not load theme preference: $error');
    }
  }

  void setWhiteTheme(bool enabled) {
    _changed = true;
    _whiteTheme.value = enabled;
    _save(enabled);
  }

  Future<void> _save(bool enabled) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_preferenceKey, enabled);
    } catch (error) {
      debugPrint('Could not save theme preference: $error');
    }
  }

  void dispose() {
    _changed = true;
    _whiteTheme.dispose();
  }
}

class WhiteAppTheme extends ThemeExtension<WhiteAppTheme> {
  const WhiteAppTheme();

  static bool isEnabled(BuildContext context) =>
      Theme.of(context).extension<WhiteAppTheme>() != null;

  static const background = Colors.white;
  static const surface = Color(0xFFF1F6FA);
  static const border = Color(0xFFB9CAD6);
  static const foreground = Colors.black;
  static const muted = Color(0xFF465F72);
  static const accent = Color(0xFF24589B);
  static const link = Color(0xFF205D82);
  static const selected = AppColors.primarySoft;

  @override
  WhiteAppTheme copyWith() => this;

  @override
  WhiteAppTheme lerp(WhiteAppTheme? other, double t) => this;
}

extension AppThemeContext on BuildContext {
  Color _themeColor(Color current, Color white) =>
      WhiteAppTheme.isEnabled(this) ? white : current;

  // Each screen supplies its current color so the original palette is retained.
  Color backgroundColor(Color current) =>
      _themeColor(current, WhiteAppTheme.background);
  Color surfaceColor(Color current) =>
      _themeColor(current, WhiteAppTheme.surface);
  Color borderColor(Color current) =>
      _themeColor(current, WhiteAppTheme.border);
  Color foregroundColor(Color current) =>
      _themeColor(current, WhiteAppTheme.foreground);
  Color mutedColor(Color current) => _themeColor(current, WhiteAppTheme.muted);
  Color accentColor(Color current) =>
      _themeColor(current, WhiteAppTheme.accent);
  Color linkColor(Color current) => _themeColor(current, WhiteAppTheme.link);
  Color selectedColor(Color current) =>
      _themeColor(current, WhiteAppTheme.selected);

  LinearGradient themedGradient(
    LinearGradient current, {
    Color white = WhiteAppTheme.background,
  }) => WhiteAppTheme.isEnabled(this)
      ? LinearGradient(colors: [white, white])
      : current;

  TextStyle themedText(TextStyle current) {
    final color = current.color;
    if (color == null || !WhiteAppTheme.isEnabled(this)) return current;
    final isPrimary = color == Colors.white;
    final themedColor = isPrimary
        ? WhiteAppTheme.foreground
        : WhiteAppTheme.muted;
    return current.copyWith(
      color: themedColor,
      decorationColor: current.decorationColor == Colors.white
          ? themedColor
          : current.decorationColor,
    );
  }
}
