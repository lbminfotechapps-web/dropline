import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

class WorkDetailsCard extends StatelessWidget {
  final VoidCallback onTap;

  const WorkDetailsCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          child: Row(
            children: [
              Container(
                height: 37,
                width: 37,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryText, width: 1.8),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primaryText,
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Photo · Note · Audio · PDF',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryText,
                size: 27,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PunchWorkSessionCard extends StatelessWidget {
  final String workedDuration;
  final String clockInTime;
  final String currentTime;
  final bool isLoading;

  const PunchWorkSessionCard({
    super.key,
    required this.workedDuration,
    required this.clockInTime,
    required this.currentTime,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
      decoration: BoxDecoration(
        color: context.surfaceColor(AppColors.cardBackground),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.borderColor(AppColors.border),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'Clocked in',
                style: TextStyle(
                  color: context.foregroundColor(AppColors.textPrimary),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            'Time worked',
            style: TextStyle(
              color: context.mutedColor(AppColors.textSecondary),
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 7),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isLoading ? '--:--:--' : workedDuration,
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 66,
                fontWeight: FontWeight.w500,
                letterSpacing: -2,
                height: 1.1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'hours : minutes : seconds',
            style: TextStyle(
              color: context.mutedColor(AppColors.textSecondary),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 21),

          Divider(color: context.borderColor(AppColors.border), thickness: 1),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _timeDetail(
                  context,
                  label: 'Clocked in at',
                  value: clockInTime,
                ),
              ),

              Container(
                height: 51,
                width: 1,
                color: context.borderColor(AppColors.border),
              ),

              Expanded(
                child: _timeDetail(
                  context,
                  label: 'Current time',
                  value: currentTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeDetail(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.mutedColor(AppColors.textSecondary),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: context.foregroundColor(AppColors.textPrimary),
            fontSize: 23,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
