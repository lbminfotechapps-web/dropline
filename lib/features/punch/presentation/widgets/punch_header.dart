import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class PunchHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final double scale;

  const PunchHeader({
    super.key,
    required this.title,
    this.onBack,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(28 * scale),
          child: InkWell(
            onTap: onBack ?? () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(28 * scale),
            child: Container(
              width: 78 * scale,
              height: 78 * scale,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28 * scale),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.20),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.white,
                size: 38 * scale,
              ),
            ),
          ),
        ),
        SizedBox(width: 34 * scale),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headingLarge.copyWith(
              fontSize: 40 * scale,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
