import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

class DashboardBackground extends StatelessWidget {
  final Widget child;

  const DashboardBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: context.themedGradient(AppColors.backgroundGradient),
      ),
      child: child,
    );
  }
}