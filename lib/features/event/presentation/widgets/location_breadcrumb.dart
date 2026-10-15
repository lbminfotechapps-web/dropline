
import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class LocationBreadcrumbItem {
  final String title;
  final VoidCallback? onTap;

  const LocationBreadcrumbItem({
    required this.title,
    this.onTap,
  });
}

class LocationBreadcrumb extends StatelessWidget {
  final List<LocationBreadcrumbItem> items;

  const LocationBreadcrumb({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _buildChip(
              item: items[index],
              isActive: index == items.length - 1,
            ),

            if (index != items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip({
    required LocationBreadcrumbItem item,
    required bool isActive,
  }) {
    final borderColor = isActive
        ? const Color(0xFFACEE70)
        : AppColors.white.withValues(alpha: 0.22);

    return Material(
      color: isActive
          ? const Color(0xFFACEE70).withValues(alpha: 0.12)
          : AppColors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Text(
            item.title,
            maxLines: 1,
            style: AppTextStyles.labelMedium.copyWith(
              color: isActive
                  ? const Color(0xFFB9F27D)
                  : AppColors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
