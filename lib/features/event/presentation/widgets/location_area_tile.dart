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
                  ? const Color(0xFFACEE70)
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
                  color: const Color(0xFF2D394C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: AppColors.white,
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
                      style:
                          AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}