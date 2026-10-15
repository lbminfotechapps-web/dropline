
import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class DashboardDateCard extends StatelessWidget {
  final DateTime date;

  const DashboardDateCard({
    super.key,
    required this.date,
  });

  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  static const List<String> _days = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY',
    'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY',
  ];

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${date.day.toString().padLeft(2, '0')} '
        '${_months[date.month - 1]} ${date.year}';

    final dayText = _days[date.weekday - 1];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 26,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dateText,
              style: AppTextStyles.headingLarge.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            dayText,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
