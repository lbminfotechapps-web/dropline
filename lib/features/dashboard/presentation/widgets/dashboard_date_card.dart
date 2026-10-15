import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class DashboardDateCard extends StatelessWidget {
  final DateTime date;

  const DashboardDateCard({super.key, required this.date});

  static const List<String> _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  static const List<String> _days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 591;
    final dateText =
        '${date.day.toString().padLeft(2, '0')} '
        '${_months[date.month - 1]} ${date.year}';

    final dayText = _days[date.weekday - 1];

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 165 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 30 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(40 * scale),
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
                fontSize: 40 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          SizedBox(height: 8 * scale),

          Text(
            dayText,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 28 * scale,
              letterSpacing: 4 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
