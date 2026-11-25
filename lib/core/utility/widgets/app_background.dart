import 'package:dropline/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (WhiteAppTheme.isEnabled(context)) {
      return ColoredBox(color: WhiteAppTheme.background, child: child);
    }
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/images/splash.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}