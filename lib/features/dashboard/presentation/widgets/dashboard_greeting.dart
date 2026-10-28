import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class DashboardGreeting extends StatelessWidget {
  final String name;
  final DateTime dateTime;
  final VoidCallback? onLogout;
  final VoidCallback? onMe;

  const DashboardGreeting({
    super.key,
    required this.name,
    required this.dateTime,
    this.onLogout,
    this.onMe,
  });

  String get greeting {
    if (dateTime.hour < 12) {
      return 'Good Morning';
    } else if (dateTime.hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 591;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '$greeting $name!',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 36 * scale,
              height: 1.2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Logout',
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          color: AppTextStyles.headingMedium.color,
        ),
        TextButton(
          onPressed: onMe,
          style: TextButton.styleFrom(
            foregroundColor: AppTextStyles.headingMedium.color,
            minimumSize: const Size(40, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text('Me'),
        ),
      ],
    );
  }
}
