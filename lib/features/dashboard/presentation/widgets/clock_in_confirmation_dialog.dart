import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

class ClockInConfirmationDialog extends StatelessWidget {
  const ClockInConfirmationDialog({
    super.key,
    required this.workspace,
    required this.projectName,
    required this.clockInTime,
  });

  final String workspace;
  final String projectName;
  final DateTime clockInTime;

  @override
  Widget build(BuildContext context) {
    final time =
        '${clockInTime.hour.toString().padLeft(2, '0')}:'
        '${clockInTime.minute.toString().padLeft(2, '0')}';

    return Dialog(
      backgroundColor: AppColors.clockInConfirmationBackground,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
          child: DefaultTextStyle(
            style: const TextStyle(color: AppColors.primaryText, fontSize: 14),
            textAlign: TextAlign.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Confirm clock-in',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text('Please check your details.'),
                const SizedBox(height: 12),
                _detail('Workspace', workspace),
                const SizedBox(height: 10),
                _detail('Project', projectName),
                Divider(
                  height: 26,
                  color: AppColors.primaryText.withValues(alpha: 0.15),
                ),
                const Text(
                  'Clock-in time',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.clockInConfirmationAction,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'OK, clock in',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryText,
                  ),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ],
  );
}
