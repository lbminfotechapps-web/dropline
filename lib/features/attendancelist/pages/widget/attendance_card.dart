import 'dart:io';

import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/features/attendancelist/data/model/attendance_record.dart';
import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  final AttendanceRecord? record;

  const AttendancePage({super.key, this.record});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _siteController;
  late TextEditingController _noteController;

  DateTime? _selectedDate;
  TimeOfDay? _inTime;
  TimeOfDay? _outTime;

  final List<File> _photos = [];
  final List<String> _recordings = [];

  bool get isEdit => widget.record != null;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    _siteController = TextEditingController(text: record?.siteName ?? '');

    _noteController = TextEditingController(text: record?.note ?? '');

    if (record != null) {
      _selectedDate = _parseDate(record.date);
      _inTime = _parseTime(record.inTime);
      _outTime = _parseTime(record.outTime);
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _siteController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
        ),

        title: Text(
          isEdit ? 'Edit Attendance' : 'Add Attendance',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),

      // =========================================================
      // BODY
      // =========================================================
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // SITE
              // =================================================
              const _FieldTitle(title: 'Site'),

              const SizedBox(height: 7),

              TextFormField(
                controller: _siteController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter site name';
                  }

                  return null;
                },
                decoration: _inputDecoration(hint: 'Enter site name'),
              ),

              const SizedBox(height: 20),

              // =================================================
              // DATE
              // =================================================
              const _FieldTitle(title: 'Attendance Date'),

              const SizedBox(height: 7),

              _buildDateField(),

              const SizedBox(height: 20),

              // =================================================
              // TIME
              // =================================================
              const _FieldTitle(title: 'Attendance Time'),

              const SizedBox(height: 7),

              Row(
                children: [
                  Expanded(
                    child: _TimePickerBox(
                      title: 'IN',
                      value: _inTime == null
                          ? '--:--'
                          : _inTime!.format(context),
                      selected: _inTime != null,
                      onTap: _selectInTime,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _TimePickerBox(
                      title: 'OUT',
                      value: _outTime == null
                          ? '--:--'
                          : _outTime!.format(context),
                      selected: _outTime != null,
                      onTap: _selectOutTime,
                    ),
                  ),
                ],
              ),

              // =================================================
              // TOTAL TIME
              // =================================================
              if (_inTime != null && _outTime != null) ...[
                const SizedBox(height: 10),
                _buildTotalTime(),
              ],

              const SizedBox(height: 20),

              // =================================================
              // NOTE
              // =================================================
              const _FieldTitle(title: 'Site Note'),

              const SizedBox(height: 7),

              TextFormField(
                controller: _noteController,
                maxLines: 4,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration(
                  hint: 'Write site work details...',
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // ATTACHMENTS
              // =================================================
              Row(
                children: [
                  const Expanded(child: _FieldTitle(title: 'Attachments')),

                  if (_photos.isNotEmpty || _recordings.isNotEmpty)
                    Text(
                      '${_photos.length + _recordings.length} files',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Appcolors.primaryColor,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  // PHOTO
                  Expanded(
                    child: _AttachmentButton(
                      icon: Icons.photo_camera_outlined,
                      title: 'Photo',
                      count: _photos.length,
                      onTap: _addDummyPhoto,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // RECORDING
                  Expanded(
                    child: _AttachmentButton(
                      icon: Icons.mic_none_rounded,
                      title: 'Recording',
                      count: _recordings.length,
                      onTap: _addRecording,
                    ),
                  ),
                ],
              ),

              // =================================================
              // RECORDINGS
              // =================================================
              if (_recordings.isNotEmpty) ...[
                const SizedBox(height: 12),

                ...List.generate(_recordings.length, (index) {
                  return _recordingItem(index);
                }),
              ],

              const SizedBox(height: 28),

              // =================================================
              // SAVE
              // =================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Appcolors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'UPDATE ATTENDANCE' : 'SAVE ATTENDANCE',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _buildDateField() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFDDE3E0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),

              const Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: Appcolors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOTAL TIME
  // ============================================================

  Widget _buildTotalTime() {
    final duration = _calculateDuration();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Appcolors.primaryColor.withOpacity(.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text(
            'Total Time',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF727A76),
            ),
          ),

          const Spacer(),

          Text(
            '${duration.$1.toString().padLeft(2, '0')} Hr  '
            '${duration.$2.toString().padLeft(2, '0')} min',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Appcolors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECORDING ITEM
  // ============================================================

  Widget _recordingItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E5E3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mic_none_rounded,
            size: 18,
            color: Appcolors.primaryColor,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              _recordings[index],
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),

          InkWell(
            onTap: () {
              setState(() {
                _recordings.removeAt(index);
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.close, size: 17, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Appcolors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedDate = result;
      });
    }
  }

  // ============================================================
  // IN TIME
  // ============================================================

  Future<void> _selectInTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _inTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Appcolors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _inTime = result;
      });
    }
  }

  // ============================================================
  // OUT TIME
  // ============================================================

  Future<void> _selectOutTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _outTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Appcolors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _outTime = result;
      });
    }
  }

  // ============================================================
  // ATTACHMENTS
  // ============================================================

  void _addDummyPhoto() {
    // Connect ImagePicker here.
    _showMessage('Connect your camera/gallery here');
  }

  void _addRecording() {
    setState(() {
      _recordings.add('site_recording_${_recordings.length + 1}.m4a');
    });
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showMessage('Please select attendance date');
      return;
    }

    if (_inTime == null) {
      _showMessage('Please select IN time');
      return;
    }

    if (_outTime == null) {
      _showMessage('Please select OUT time');
      return;
    }

    final startMinutes = (_inTime!.hour * 60) + _inTime!.minute;

    final endMinutes = (_outTime!.hour * 60) + _outTime!.minute;

    if (endMinutes < startMinutes) {
      _showMessage('OUT time cannot be before IN time');
      return;
    }

    debugPrint('==============================');
    debugPrint('ATTENDANCE');
    debugPrint('==============================');
    debugPrint('Site : ${_siteController.text}');
    debugPrint('Date : $_selectedDate');
    debugPrint('IN   : $_inTime');
    debugPrint('OUT  : $_outTime');
    debugPrint('Note : ${_noteController.text}');
    debugPrint('Photos : ${_photos.length}');
    debugPrint('Recordings : ${_recordings.length}');
    debugPrint('==============================');

    _showMessage(
      isEdit
          ? 'Attendance updated successfully'
          : 'Attendance saved successfully',
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pop(context);
    }
  }

  // ============================================================
  // DURATION
  // ============================================================

  (int, int) _calculateDuration() {
    if (_inTime == null || _outTime == null) {
      return (0, 0);
    }

    final start = (_inTime!.hour * 60) + _inTime!.minute;

    var end = (_outTime!.hour * 60) + _outTime!.minute;

    if (end < start) {
      end += 24 * 60;
    }

    final total = end - start;

    return (total ~/ 60, total % 60);
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  DateTime? _parseDate(String value) {
    try {
      final parts = value.split(' ');

      if (parts.length != 3) {
        return null;
      }

      const months = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      };

      return DateTime(
        int.parse(parts[2]),
        months[parts[1]] ?? 1,
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // TIME PARSER
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

      final time = parts[0].split(':');

      int hour = int.parse(time[0]);
      final minute = int.parse(time[1]);

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

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF989F9B)),

      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFDDE3E0)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFDDE3E0)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Appcolors.primaryColor, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// ======================================================================
// FIELD TITLE
// ======================================================================

class _FieldTitle extends StatelessWidget {
  final String title;

  const _FieldTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Appcolors.darkColor,
      ),
    );
  }
}

// ======================================================================
// TIME PICKER BOX
// ======================================================================

class _TimePickerBox extends StatelessWidget {
  final String title;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _TimePickerBox({
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 76,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF10B95A) : const Color(0xFFFFBF13),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const Spacer(),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// ATTACHMENT BUTTON
// ======================================================================

class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  const _AttachmentButton({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE3E0)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Appcolors.primaryColor),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Appcolors.darkColor,
                  ),
                ),
              ),

              Container(
                constraints: const BoxConstraints(minWidth: 24),
                height: 24,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: count > 0
                      ? Appcolors.primaryColor
                      : const Color(0xFFF0F2F1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: count > 0 ? Colors.white : const Color(0xFF7A827E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
