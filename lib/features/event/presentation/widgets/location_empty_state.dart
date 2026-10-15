import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';


import '../../../../core/theme/app_text_styles.dart';

class LocationEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  const LocationEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.white.withValues(
                  alpha: 0.25,
                ),
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 34,
              color: AppColors.white,
            ),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}