import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class WorkDetailsCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  final double scale;

  const WorkDetailsCard({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(88 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(88 * scale),
        child: Ink(
          width: double.infinity,
          height: 258 * scale,
          padding: EdgeInsets.symmetric(horizontal: 24 * scale),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF42658D), Color(0xFF1B3C65)],
            ),
            borderRadius: BorderRadius.circular(88 * scale),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 28 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12 * scale),
              Text(
                value,
                style: AppTextStyles.displayMedium.copyWith(
                  fontSize: 72 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
