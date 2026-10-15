import 'dart:math' as math;
import 'dart:io';

import 'widgets/audio_recorder_dialog.dart';
import 'package:cross_file/cross_file.dart';

import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Note composer. Camera and recording can be supplied by the host screen.
class AddEventPage extends StatefulWidget {
  const AddEventPage({
    super.key,
    this.projectName = 'TRIBECA',
    this.onCamera,
    this.onRecordAudio,
  });

  final String projectName;
  final VoidCallback? onCamera;
  final VoidCallback? onRecordAudio;

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  final _timeController = ScrollController(initialScrollOffset: 104);
  final _attachments = <XFile>[];
  int _selectedTime = 2;
  int _selectedCard = 2;
  bool _picking = false;

  String _timeLabel(int index) {
    final minutes = 11 * 60 + 15 + index * 15;
    return '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
        '${(minutes % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _pickAttachment(FileType type) async {
    if (_picking) return;
    _picking = true;
    try {
      final result = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: type == FileType.custom ? ['pdf'] : null,
      );
      if (!mounted || result.isEmpty) return;
      setState(() => _attachments.addAll(result.map((file) => file.xFile)));
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open files. Please try again.'),
          ),
        );
      }
    } finally {
      _picking = false;
    }
  }

  Future<void> _openRecorder() async {
    FocusScope.of(context).unfocus();
    final path = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AudioRecorderDialog(),
    );
    if (!mounted || path == null) return;
    try {
      final file = File(path);
      if (!await file.exists()) throw StateError('Recording missing');
      final attachment = XFile(path);
      if (!mounted) return;
      setState(() {
        _attachments.add(attachment);
        _selectedCard = _attachments.length - 1;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to attach recording. Please try again.'),
          ),
        );
      }
    }
  }

  void _completeEvent() {
    if (_noteController.text.trim().isEmpty && _attachments.isEmpty) {
      _noteFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    // Return the draft to the caller for persistence.
    Navigator.of(context).maybePop({
      'note': _noteController.text.trim(),
      'time': _timeLabel(_selectedTime),
      'attachments': List<XFile>.of(_attachments),
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.eventBackgroundBottom,
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = (constraints.maxWidth / 390).clamp(0.8, 1.4);
                final horizontal = 26 * scale;
                final cardHeight = math.max(
                  245.0,
                  constraints.maxHeight - 305 * scale,
                );
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(top: 18 * scale, bottom: 12 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontal),
                        child: Row(
                          children: [
                            Container(
                              width: 30 * scale,
                              height: 30 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.white.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: AppColors.white.withValues(
                                    alpha: 0.16,
                                  ),
                                ),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: 'Back',
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  size: 24 * scale,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 10 * scale),
                            Text(
                              widget.projectName,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontSize: 20 * scale,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      Container(
                        height: cardHeight,
                        margin: EdgeInsets.symmetric(horizontal: horizontal),
                        padding: EdgeInsets.fromLTRB(
                          12 * scale,
                          10 * scale,
                          12 * scale,
                          4 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.eventNoteSurface,
                          borderRadius: BorderRadius.circular(26 * scale),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _noteController,
                                focusNode: _noteFocus,
                                expands: true,
                                minLines: null,
                                maxLines: null,
                                textAlignVertical: TextAlignVertical.top,
                                keyboardType: TextInputType.multiline,
                                cursorColor: AppColors.white,
                                style: AppTextStyles.inputText.copyWith(
                                  fontSize: 16 * scale,
                                  height: 1.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Write a note...',
                                  hintStyle: AppTextStyles.inputHint.copyWith(
                                    fontSize: 16 * scale,
                                    color: AppColors.textSecondary,
                                  ),
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.all(6 * scale),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _timeLabel(_selectedTime),
                                  style: AppTextStyles.headingLarge.copyWith(
                                    fontSize: 30 * scale,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Record voice note',
                                  onPressed:
                                      widget.onRecordAudio ?? _openRecorder,
                                  icon: const Icon(
                                    Icons.mic_none_rounded,
                                    color: AppColors.white,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Edit note',
                                  onPressed: _noteFocus.requestFocus,
                                  icon: const Icon(
                                    Icons.edit_square,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 13 * scale),
                      SizedBox(
                        height: 64 * scale,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontal + 7 * scale,
                          ),
                          itemCount: math.max(5, _attachments.length),
                          separatorBuilder: (_, index) =>
                              SizedBox(width: 10 * scale),
                          itemBuilder: (context, index) {
                            final attached = index < _attachments.length
                                ? _attachments[index]
                                : null;
                            return Tooltip(
                              message:
                                  attached?.name ??
                                  [
                                    'Photo',
                                    'Photo',
                                    'Audio',
                                    'Photo',
                                    'Note',
                                  ][index % 5],
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedCard = index),
                                child: Container(
                                  width: 57 * scale,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: index % 5 == 2 || index % 5 == 4
                                        ? AppColors.eventTileLight
                                        : AppColors.eventTilePeach,
                                    borderRadius: BorderRadius.circular(
                                      16 * scale,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        blurRadius: 8,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: attached != null
                                      ? Text(
                                          attached.name,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.black,
                                                fontSize: 10 * scale,
                                              ),
                                        )
                                      : Icon(
                                          index % 5 == 2
                                              ? Icons.mic_none_rounded
                                              : index % 5 == 4
                                              ? Icons.edit_note_rounded
                                              : Icons.image_outlined,
                                          color: AppColors.black,
                                          size: 24 * scale,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          math.max(5, _attachments.length),
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: (_selectedCard == index ? 26 : 8) * scale,
                            height: 8 * scale,
                            margin: EdgeInsets.symmetric(horizontal: 3 * scale),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(
                                alpha: _selectedCard == index ? 1 : 0.25,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 17 * scale),
                      SizedBox(
                        height: 34 * scale,
                        child: ListView.separated(
                          controller: _timeController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: 12,
                          separatorBuilder: (_, index) =>
                              SizedBox(width: 7 * scale),
                          itemBuilder: (context, index) => Semantics(
                            selected: _selectedTime == index,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () =>
                                  setState(() => _selectedTime = index),
                              child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 9 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(
                                    alpha: 0.06,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _selectedTime == index
                                        ? AppColors.eventTimeSelected
                                        : AppColors.white.withValues(
                                            alpha: 0.18,
                                          ),
                                    width: _selectedTime == index ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  _timeLabel(index),
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontSize: 15 * scale,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 14 * scale),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 19 * scale),
                        padding: EdgeInsets.all(13 * scale),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(28 * scale),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _tool(
                              'Attach PDF',
                              Icons.picture_as_pdf_outlined,
                              AppColors.eventToolBlue,
                              () => _pickAttachment(FileType.custom),
                              scale,
                            ),
                            _tool(
                              'Write note',
                              Icons.edit_note_rounded,
                              AppColors.eventToolMint,
                              _noteFocus.requestFocus,
                              scale,
                            ),
                            _tool(
                              'Add photo',
                              Icons.camera_alt_outlined,
                              AppColors.eventToolPurple,
                              widget.onCamera ??
                                  () => _pickAttachment(FileType.image),
                              scale,
                            ),
                            _tool(
                              'Record voice note',
                              Icons.mic_none_rounded,
                              AppColors.eventToolOrange,
                              widget.onRecordAudio ?? _openRecorder,
                              scale,
                            ),
                            SizedBox(
                              height: 48 * scale,
                              child: FilledButton(
                                onPressed: _completeEvent,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.eventToolCyan,
                                  foregroundColor: AppColors.black,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18 * scale,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      17 * scale,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Event',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: AppColors.black,
                                    fontSize: 15 * scale,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _tool(
    String label,
    IconData icon,
    Color colour,
    VoidCallback onTap,
    double scale,
  ) {
    return SizedBox(
      width: 47 * scale,
      height: 48 * scale,
      child: IconButton.filled(
        tooltip: label,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: colour,
          foregroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scale),
          ),
        ),
        icon: Icon(icon, size: 24 * scale),
      ),
    );
  }
}
