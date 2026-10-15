import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class PunchTimeCard extends StatelessWidget {
  final String time;
  final double height;
  final double fontSize;
  final double radius;

  const PunchTimeCard({
    super.key,
    required this.time,
    this.height = 160,
    this.fontSize = 92,
    this.radius = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            time,
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -3,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
