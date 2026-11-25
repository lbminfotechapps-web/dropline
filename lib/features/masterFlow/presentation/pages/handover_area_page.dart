import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:dropline/features/masterFlow/presentation/pages/handover_action_pages.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

// Import your existing:
// CustomAppBar
// AppColors
// HandoverAreaData
// HandoverCheckSheetPage

const Color _primaryAccent = AppColors.primary;
const Color _blue = Color(0xFFA7D3FF);
const Color _darkText = Color(0xFF092537);

// ------------------------------------
// HAND OVER AREA PAGE
// ------------------------------------

class HandOverAreaPage extends StatefulWidget {
  const HandOverAreaPage({
    super.key,
    required this.data,
  });

  final HandoverAreaData data;

  @override
  State<HandOverAreaPage> createState() =>
      _HandOverAreaPageState();
}

class _HandOverAreaPageState extends State<HandOverAreaPage> {
  static const Color _primaryAccent = AppColors.primary;
  static const Color _blue = Color(0xFFA7D3FF);

  final TextEditingController noteController =
      TextEditingController();

  final TextEditingController remainingController =
      TextEditingController();

  List<String>? answers;
  List<String> attachments = [];

  bool workNotReady = false;
  bool isSubmitting = false;

  bool get answersSaved =>
      answers != null &&
      answers!.length == widget.data.questions.length &&
      answers!.every((answer) => answer.isNotEmpty);

  bool get canSubmit {
    if (isSubmitting) return false;

    if (workNotReady) {
      return remainingController.text.trim().isNotEmpty;
    }

    return answersSaved;
  }

  // Open check sheet
  Future<void> openCheckSheet() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => HandoverCheckSheetPage(
          data: widget.data,
          existingAnswers: answers,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      answers = result;
    });
  }

  // Toggle between Hand over / Save progress
  void toggleWorkNotReady(bool? value) {
    FocusScope.of(context).unfocus();

    setState(() {
      workNotReady = value ?? false;
    });
  }

  // Save progress
  Future<void> saveProgress() async {
    if (!canSubmit) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final remainingWork =
          remainingController.text.trim();

      // TODO: Call Save Progress API.
      //
      // Data:
      // widget.data
      // remainingWork
      // attachments
      // workNotReady = true

      debugPrint('SAVE PROGRESS');
      debugPrint('Remaining work: $remainingWork');
      debugPrint('Attachments: $attachments');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connect Save Progress API to save data',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // Send handover
  Future<void> sendHandover() async {
    if (!canSubmit) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final note = noteController.text.trim();

      // TODO: Call Send Handover API.
      //
      // Data:
      // widget.data
      // answers
      // note
      // attachments
      // workNotReady = false

      debugPrint('SEND HANDOVER');
      debugPrint('Note: $note');
      debugPrint('Answers: $answers');
      debugPrint('Attachments: $attachments');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connect Send Handover API to submit data',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    remainingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor(AppColors.background),
      resizeToAvoidBottomInset: true,

      appBar: CustomAppBar(
        title: workNotReady
            ? 'Save progress'
            : 'Hand over area',
        subtitle: widget.data.projectName,
        backgroundColor: context.backgroundColor(AppColors.background),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          9, 17, 9, 25,
        ),
        children: [
          // Common area heading
          HandoverAreaHeader(data: widget.data),

          const SizedBox(height: 15),

          // --------------------------------
          // UNCHECKED - HAND OVER AREA UI
          // --------------------------------
          if (!workNotReady) ...[
            // Sending to
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
              ),
              decoration: BoxDecoration(
                color: context.surfaceColor(AppColors.surface),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.borderColor(AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Sending to',
                    style: TextStyle(
                      color: context.linkColor(_blue),
                      fontSize: 12,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    widget.data.receivingCompany,
                    style: TextStyle(
                      color: context.foregroundColor(AppColors.textPrimary),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Handing on check sheet',
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            // Check sheet card
            InkWell(
              onTap: openCheckSheet,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: context.surfaceColor(AppColors.surface),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: answersSaved
                        ? AppColors.primaryBorder
                        : context.borderColor(AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 35,
                      width: 35,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF214637),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assignment_turned_in_outlined,
                        color: context.accentColor(_primaryAccent),
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.data.checkSheetCode} · '
                            '${widget.data.checkSheetTitle}',
                            style: TextStyle(
                              color: context.foregroundColor(
                                AppColors.textPrimary,
                              ),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            answersSaved
                                ? 'Answers saved'
                                : 'Tap to answer · Required',
                            style: TextStyle(
                              color: answersSaved
                                  ? context.accentColor(_primaryAccent)
                                  : context.linkColor(_blue),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      answersSaved
                          ? Icons.check
                          : Icons.chevron_right,
                      color: answersSaved ? context.accentColor(_primaryAccent) : context.linkColor(_blue),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 17),

            Text(
              'Note (optional)',
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: noteController,
              minLines: 3,
              maxLines: 3,
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 14,
              ),
              decoration: handoverTextDecoration(
                'Add anything the team should know.',
              ),
            ),

            const SizedBox(height: 9),
          ],

          // --------------------------------
          // CHECKED - SAVE PROGRESS UI
          // --------------------------------
          if (workNotReady) ...[
            const SizedBox(height: 2),

            Text(
              "What's left?",
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: remainingController,
              minLines: 3,
              maxLines: 3,
              onChanged: (_) {
                setState(() {});
              },
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 14,
              ),
              decoration: handoverTextDecoration(
                'Say what work remains.',
              ),
            ),

            const SizedBox(height: 9),
          ],

          // --------------------------------
          // COMMON PHOTOS AND FILES
          // --------------------------------
          HandoverAttachmentPicker(
            onChanged: (files) {
              attachments = files;
            },
          ),

          const SizedBox(height: 15),

          // --------------------------------
          // WORK NOT READY CHECKBOX
          // --------------------------------
          InkWell(
            onTap: () {
              toggleWorkNotReady(!workNotReady);
            },
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 34,
                  child: Checkbox(
                    value: workNotReady,
                    activeColor: _primaryAccent,
                    checkColor: const Color(0xFF092537),
                    side: BorderSide(
                      color: context.mutedColor(AppColors.textSecondary),
                    ),
                    onChanged: toggleWorkNotReady,
                  ),
                ),

                const SizedBox(width: 5),

                Text(
                  'Work is not ready yet',
                  style: TextStyle(
                    color: context.foregroundColor(AppColors.textPrimary),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Dynamic information text
          Text(
            workNotReady
                ? 'Only your progress is saved. '
                  'The area stays with ${widget.data.companyName}.'
                : 'The area stays with ${widget.data.companyName} '
                      'until ${widget.data.receivingCompany} accepts.',
            style: TextStyle(
              color: context.linkColor(_blue),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),

      // --------------------------------
      // DYNAMIC BOTTOM BUTTON
      // --------------------------------
      bottomNavigationBar: HandoverBottomAction(
        label: isSubmitting
            ? (workNotReady
                ? 'Saving...'
                : 'Sending...')
            : (workNotReady
                ? 'Save progress'
                : 'Send handover'),
        enabled: canSubmit,
        onPressed: () {
          if (workNotReady) {
            saveProgress();
          } else {
            sendHandover();
          }
        },
      ),
    );
  }
}

// ------------------------------------
// COMMON AREA HEADER
// ------------------------------------

class HandoverAreaHeader extends StatelessWidget {
  const HandoverAreaHeader({
    super.key,
    required this.data,
  });

  final HandoverAreaData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: context.surfaceColor(AppColors.surface),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: context.borderColor(AppColors.border)),
          ),
          child: Icon(
            Icons.location_on_outlined,
            color: context.linkColor(_blue),
            size: 19,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.area,
                style: TextStyle(
                  color: context.foregroundColor(AppColors.textPrimary),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${data.activityCode} · ${data.activityName}'
                '  ·  Visit ${data.visitNumber}',
                style: TextStyle(color: context.linkColor(_blue), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------
// COMMON TEXT FIELD DECORATION
// ------------------------------------

InputDecoration handoverTextDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: _blue,
      fontSize: 14,
    ),
    filled: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.all(12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: AppColors.border,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: _primaryAccent,
        width: 1.5,
      ),
    ),
  );
}

// ------------------------------------
// COMMON FIXED BOTTOM BUTTON
// ------------------------------------

class HandoverBottomAction extends StatelessWidget {
  const HandoverBottomAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 10, 9, 8),
      decoration: BoxDecoration(
        color: context.backgroundColor(AppColors.background),
        border: Border(
          top: BorderSide(
            color: context.borderColor(AppColors.border),
            width: 0.7,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryAccent,
              foregroundColor: _darkText,
              disabledBackgroundColor:
                  const Color(0xFF284853),
              disabledForegroundColor: context.linkColor(_blue),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------
// REUSABLE ATTACHMENT PICKER
// ------------------------------------

class HandoverAttachmentPicker extends StatefulWidget {
  const HandoverAttachmentPicker({
    super.key,
    this.onChanged,
  });

  final ValueChanged<List<String>>? onChanged;

  @override
  State<HandoverAttachmentPicker> createState() =>
      _HandoverAttachmentPickerState();
}

class _HandoverAttachmentPickerState
    extends State<HandoverAttachmentPicker> {
  final ImagePicker imagePicker = ImagePicker();

  final List<String> files = [];

  void updateFiles(List<String> selected) {
    setState(() {
      files.addAll(selected);
    });

    widget.onChanged?.call(List<String>.from(files));
  }

  void removeFile(String path) {
    setState(() {
      files.remove(path);
    });

    widget.onChanged?.call(List<String>.from(files));
  }

  void showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attachment error: $error')),
    );
  }

  Future<void> takePhoto() async {
    try {
      final photo = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (!mounted || photo == null) return;

      updateFiles([photo.path]);
    } catch (e) {
      showError(e);
    }
  }

  Future<void> choosePhotos() async {
    try {
      final photos = await imagePicker.pickMultiImage(
        imageQuality: 80,
      );

      if (!mounted || photos.isEmpty) return;

      updateFiles(
        photos.map((photo) => photo.path).toList(),
      );
    } catch (e) {
      showError(e);
    }
  }

  Future<void> attachFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
        ],
        // allowMultiple: true,
      );

      if (!mounted || result == null) return;

      updateFiles(
        result
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList(),
      );
    } catch (e) {
      showError(e);
    }
  }

  Future<void> openOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor(AppColors.surface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (sheetContext) {
        Widget option(
          IconData icon,
          String title,
          VoidCallback onTap, {
          String? subtitle,
        }) {
          return Container(
            margin: const EdgeInsets.only(bottom: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor(AppColors.border)),
            ),
            child: ListTile(
              onTap: () {
                Navigator.pop(sheetContext);
                onTap();
              },
              leading: Icon(icon, color: context.linkColor(_blue), size: 20),
              title: Text(
                title,
                style: TextStyle(
                  color: context.foregroundColor(AppColors.textPrimary),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: subtitle == null
                  ? null
                  : Text(
                      subtitle,
                      style: TextStyle(
                        color: context.linkColor(_blue),
                        fontSize: 10,
                      ),
                    ),
              trailing: Icon(
                Icons.chevron_right,
                color: context.linkColor(_blue),
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add to handover',
                        style: TextStyle(
                          color: context.foregroundColor(AppColors.textPrimary),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext),
                      icon: Icon(
                        Icons.close,
                        color: context.foregroundColor(AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                option(
                  Icons.camera_alt_outlined,
                  'Take photo',
                  takePhoto,
                ),

                option(
                  Icons.image_outlined,
                  'Choose photos',
                  choosePhotos,
                ),

                option(
                  Icons.attach_file,
                  'Attach file',
                  attachFile,
                  subtitle: 'PDF, Word or Excel',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: context.surfaceColor(AppColors.surface),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: context.borderColor(AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Photos and files',
                  style: TextStyle(
                    color: context.foregroundColor(AppColors.textPrimary),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              SizedBox(
                height: 43,
                child: OutlinedButton.icon(
                  onPressed: openOptions,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.linkColor(_blue),
                    side: BorderSide(
                      color: context.borderColor(AppColors.border),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (files.isNotEmpty) ...[
          const SizedBox(height: 7),

          ...files.map((path) {
            final name = path.split(RegExp(r'[/\\]')).last;

            return Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color: context.surfaceColor(AppColors.surface),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: context.borderColor(AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    color: context.linkColor(_blue),
                    size: 17,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.foregroundColor(AppColors.textPrimary),
                        fontSize: 12,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () => removeFile(path),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.redAccent,
                      size: 17,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
