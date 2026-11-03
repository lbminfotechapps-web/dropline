import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

class PunchHeader extends StatelessWidget {
  final String title;
  final String workspace;
  final VoidCallback? onBack;
  final VoidCallback? onMe;

  const PunchHeader({
    super.key,
    required this.title,
    this.workspace = 'Business',
    this.onBack,
    this.onMe,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onBack ?? () => Navigator.maybePop(context),
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 23,
            ),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 5),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.work_outline_rounded,
                      size: 14,
                      color: AppColors.iconColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      workspace,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        InkWell(
          onTap: onMe,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 50,
            width: 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Text(
              'ME',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

