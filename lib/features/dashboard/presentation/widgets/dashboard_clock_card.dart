import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class DashboardClockCard extends StatelessWidget {
  final DateTime dateTime;

  const DashboardClockCard({super.key, required this.dateTime});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 591;
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      height: 242 * scale,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(48 * scale),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.7),
          width: 1.2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$hours:$minutes',
          style: AppTextStyles.displayLarge.copyWith(
            fontSize: 120 * scale,
            fontWeight: FontWeight.w800,
            letterSpacing: -3,
            height: 1,
          ),
        ),
      ),
    );
  }
}
