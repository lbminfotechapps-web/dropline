import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class DashboardGreeting extends StatelessWidget {
  final String name;
  final DateTime dateTime;

  const DashboardGreeting({
    super.key,
    required this.name,
    required this.dateTime,
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
    return Text(
      '$greeting $name!',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.headingMedium.copyWith(
        fontSize: 36 * scale,
        height: 1.2,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
