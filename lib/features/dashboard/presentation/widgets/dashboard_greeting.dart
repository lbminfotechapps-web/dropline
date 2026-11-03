import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';

import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

class DashboardGreeting extends StatelessWidget {
  final String name;
  final DateTime dateTime;
  final VoidCallback? onMe;
  final VoidCallback? onLogout;

  const DashboardGreeting({
    super.key,
    required this.name,
    required this.dateTime,
    this.onMe,
    this.onLogout,
  });

  static const _days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  static const _months = [
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

  String get greeting {
    if (dateTime.hour < 12) return 'Good Morning';
    if (dateTime.hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get formattedDate {
    return '${_days[dateTime.weekday - 1]}, '
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${_months[dateTime.month - 1]} '
        '${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = name.trim().isEmpty
        ? 'There'
        : name.trim().split(RegExp(r'\s+')).first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting $firstName!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                formattedDate,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        PopupMenuButton<String>(
          tooltip: 'Profile options',
          color: AppColors.surface,
          onSelected: (value) {
            if (value == 'profile') {
              context.push('/profile');
              // onMe?.call();
            } else if (value == 'logout') {
              onLogout?.call();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Text(
                'My Profile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (onLogout != null)
              const PopupMenuItem(
                value: 'logout',
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
          ],
          child: Container(
            height: 54,
            width: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            child:Icon(Icons.person_2_rounded,color: AppColors.primaryText,)
            //  const Text(
            //   'ME',
            //   style: TextStyle(
            //     color: AppColors.primaryText,
            //     fontSize: 21,
            //     fontWeight: FontWeight.w800,
            //   ),
            // ),
          ),
        ),
      ],
    );
  }
}
