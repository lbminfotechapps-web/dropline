import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

class DashboardClockCard extends StatelessWidget {
  final DateTime dateTime;
  final VoidCallback? onEdit;

  const DashboardClockCard({super.key, required this.dateTime, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.1),
      ),
      child: Column(
        children: [
          const Text(
            'CLOCK-IN TIME',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 5),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '$hours:$minutes',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 39,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -1.4,
                  ),
                ),
              ),

              if (onEdit != null) ...[
                const SizedBox(width: 15),

                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 5),

          Text(
            onEdit != null
                ? 'You can edit your start time.'
                : 'Your start time.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

enum WorkspaceType { personal, business }

class DashboardWorkspaceCard extends StatelessWidget {
  final WorkspaceType selectedType;
  final ValueChanged<WorkspaceType> onChanged;

  const DashboardWorkspaceCard({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your workspace',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _workspaceItem(
                title: 'Personal',
                subtitle: 'Private',
                type: WorkspaceType.personal,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _workspaceItem(
                title: 'Business',
                subtitle: 'Shared projects',
                type: WorkspaceType.business,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _workspaceItem({
    required String title,
    required String subtitle,
    required WorkspaceType type,
  }) {
    final isSelected = selectedType == type;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => onChanged(type),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}





class DashboardTimeBottomSheet extends StatefulWidget {
  final DateTime initialTime;
  final String workspaceLabel;

  const DashboardTimeBottomSheet({
    super.key,
    required this.initialTime,
    this.workspaceLabel = 'Personal · Private',
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialTime,
    String workspaceLabel = 'Personal · Private',
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.sheetBackground,
      barrierColor: AppColors.black.withValues(alpha: 0.65),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => DashboardTimeBottomSheet(
        initialTime: initialTime,
        workspaceLabel: workspaceLabel,
      ),
    );
  }

  @override
  State<DashboardTimeBottomSheet> createState() =>
      _DashboardTimeBottomSheetState();
}

class _DashboardTimeBottomSheetState
    extends State<DashboardTimeBottomSheet> {
  late final TextEditingController _timeController;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();

    _selectedTime = TimeOfDay.fromDateTime(widget.initialTime);
    _timeController = TextEditingController(
      text: _formattedTime(_selectedTime),
    );
  }

  String _formattedTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    FocusScope.of(context).unfocus();

    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.primaryText,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: AppColors.surface,
              hourMinuteColor: AppColors.inputBackground,
              hourMinuteTextColor: AppColors.textPrimary,
              dialBackgroundColor: AppColors.cardBackground,
              dialHandColor: AppColors.primary,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
            child: child!,
          ),
        );
      },
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedTime = picked;
      _timeController.text = _formattedTime(picked);
    });
  }

  void _saveTime() {
    final selectedDateTime = DateTime(
      widget.initialTime.year,
      widget.initialTime.month,
      widget.initialTime.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    Navigator.of(context).pop(selectedDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        100 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.sheetHandle,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Edit clock-in time',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            widget.workspaceLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'START TIME',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.iconColor,
                      size: 20,
                    ),

                    const SizedBox(width: 14),

                    Text(
                      _timeController.text,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const Spacer(),

                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(
                        color: AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _saveTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: const Text(
                      'Save time',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
