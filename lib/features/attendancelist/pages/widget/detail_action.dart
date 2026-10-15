import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

class DetailAction extends StatelessWidget {
  final String inTime;
  final String outTime;

  const DetailAction({super.key, required this.inTime, required this.outTime});

  @override
  Widget build(BuildContext context) {
    final duration = _calculateDuration(inTime, outTime);

    return Container(
      width: 62,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Appcolors.primaryColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Appcolors.primaryColor.withOpacity(0.14)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // =====================================================
          // CLOCK ICON
          // =====================================================
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: Appcolors.primaryColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 16,
              color: Appcolors.primaryColor,
            ),
          ),

          const SizedBox(height: 6),

          // =====================================================
          // HOURS
          // =====================================================
          Text(
            duration.$1.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 19,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Appcolors.darkColor,
            ),
          ),

          const SizedBox(height: 2),

          const Text(
            'Hr',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7B8580),
            ),
          ),

          const SizedBox(height: 5),

          // =====================================================
          // MINUTES
          // =====================================================
          Text(
            duration.$2.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 16,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Appcolors.darkColor,
            ),
          ),

          const SizedBox(height: 2),

          const Text(
            'min',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7B8580),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALCULATE DURATION
  // ============================================================

  (int, int) _calculateDuration(String inTime, String outTime) {
    final start = _parseTime(inTime);
    final end = _parseTime(outTime);

    if (start == null || end == null) {
      return (0, 0);
    }

    final startMinutes = (start.hour * 60) + start.minute;

    var endMinutes = (end.hour * 60) + end.minute;

    // Handle overnight attendance
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }

    final totalMinutes = endMinutes - startMinutes;

    return (totalMinutes ~/ 60, totalMinutes % 60);
  }

  // ============================================================
  // PARSE TIME
  // ============================================================

  TimeOfDay? _parseTime(String value) {
    try {
      if (value.trim().isEmpty) {
        return null;
      }

      final parts = value.trim().split(' ');

      if (parts.length != 2) {
        return null;
      }

      final timeParts = parts[0].split(':');

      if (timeParts.length != 2) {
        return null;
      }

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final period = parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }
}
