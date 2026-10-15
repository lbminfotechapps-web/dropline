
import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class DashboardProjectCard extends StatelessWidget {
  final String? selectedProject;
  final VoidCallback onTap;

  const DashboardProjectCard({
    super.key,
    required this.onTap,
    this.selectedProject,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 85),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.cardBorder.withValues(
                alpha: 0.65,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            selectedProject ?? 'SELECT PROJECT',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleLarge.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ),
    );
  }
}
