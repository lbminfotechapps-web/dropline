import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class LocationAreaTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSelected;

  const LocationAreaTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3C485B),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.transparent,
              width: 1.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: context.surfaceColor(const Color(0xFF2D394C)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.folder_outlined,
                  color: context.foregroundColor(AppColors.white),
                  size: 23,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context
                          .themedText(AppTextStyles.titleMedium)
                          .copyWith(
                            fontWeight: FontWeight.w500,
                            color: context.foregroundColor(AppColors.white),
                          ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      style: context
                          .themedText(AppTextStyles.bodySmall)
                          .copyWith(
                            color: context.mutedColor(AppColors.textSecondary),
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right_rounded,
                color: context.mutedColor(AppColors.textSecondary),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}