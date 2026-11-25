import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

// Import your existing CustomAppBar and AppColors.

// ---------------------------------------------
// COMMON DATA
// ---------------------------------------------

class HandoverAreaData {
  final String area;
  final String projectName;
  final String companyName;
  final String receivingCompany;
  final String checkSheetCode;
  final String checkSheetTitle;
  final String activityCode;
  final String activityName;
  final int visitNumber;
  final List<String> questions;

  const HandoverAreaData({
    required this.area,
    required this.projectName,
    required this.companyName,
    required this.receivingCompany,
    required this.checkSheetCode,
    required this.checkSheetTitle,
    required this.activityCode,
    required this.activityName,
    required this.visitNumber,
    required this.questions,
  });
}

const handoverAccent = AppColors.primary;

InputDecoration handoverInputDecoration(BuildContext context, String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: context.mutedColor(AppColors.textSecondary),
      fontSize: 14,
    ),
    filled: true,
    fillColor: context.backgroundColor(AppColors.background),
    contentPadding: const EdgeInsets.all(12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.borderColor(AppColors.border)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.accentColor(handoverAccent), width: 1.5),
    ),
  );
}

ButtonStyle handoverOutlineStyle(BuildContext context) {
  return OutlinedButton.styleFrom(
    foregroundColor: context.foregroundColor(AppColors.textPrimary),
    side: BorderSide(color: context.borderColor(AppColors.border)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

Widget handoverBottomButton(
  BuildContext context, {
  required String title,
  required VoidCallback? onPressed,
  IconData? icon,
}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
    decoration: BoxDecoration(
      color: context.backgroundColor(AppColors.background),
      border: Border(
        top: BorderSide(color: context.borderColor(AppColors.border)),
      ),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 46,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
          label: Text(title),
          style: ElevatedButton.styleFrom(
            backgroundColor: handoverAccent,
            foregroundColor: const Color(0xFF092537),
            disabledBackgroundColor: const Color(0xFF284853),
            disabledForegroundColor: context.mutedColor(
              AppColors.textSecondary,
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget handoverAreaHeading(BuildContext context, HandoverAreaData data) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 35,
        height: 36,
        decoration: BoxDecoration(
          color: context.surfaceColor(AppColors.surface),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: context.borderColor(AppColors.border)),
        ),
        child: const Icon(
          Icons.location_on_outlined,
          color: Color(0xFFA7D3FF),
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
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${data.activityCode} · ${data.activityName} · Visit ${data.visitNumber}',
              style: const TextStyle(color: Color(0xFFA7D3FF), fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );
}

// ---------------------------------------------
// HAND OVER AREA SCREEN
// ---------------------------------------------

class HandOverAreaPage extends StatefulWidget {
  const HandOverAreaPage({super.key, required this.data});

  final HandoverAreaData data;

  @override
  State<HandOverAreaPage> createState() => _HandOverAreaPageState();
}

class _HandOverAreaPageState extends State<HandOverAreaPage> {
  final noteController = TextEditingController();
  final remainingController = TextEditingController();
  final _progressFormKey = GlobalKey<FormState>();
  final ImagePicker imagePicker = ImagePicker();

  List<String>? answers;
  final List<String> attachments = [];

  bool workNotReady = false;
  bool submitting = false;

  bool get answersSaved =>
      answers != null &&
      answers!.length == widget.data.questions.length &&
      answers!.every((answer) => answer.isNotEmpty);

  Future<void> openCheckSheet() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HandoverCheckSheetPage(data: widget.data, existingAnswers: answers),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      answers = result;
    });
  }

  Future<void> addAttachments() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor(AppColors.surface),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(
                        Icons.close,
                        color: context.foregroundColor(AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _attachmentOption(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take photo',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    takePhoto();
                  },
                ),
                _attachmentOption(
                  icon: Icons.image_outlined,
                  title: 'Choose photos',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    choosePhotos();
                  },
                ),
                _attachmentOption(
                  icon: Icons.attach_file,
                  title: 'Attach file',
                  subtitle: 'PDF, Word or Excel',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    attachFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachmentOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: context.surfaceColor(AppColors.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: context.borderColor(AppColors.border)),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: const Color(0xFFA7D3FF)),
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
                  style: const TextStyle(
                    color: Color(0xFFA7D3FF),
                    fontSize: 10,
                  ),
                ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFA7D3FF)),
        ),
      ),
    );
  }

  Future<void> takePhoto() async {
    try {
      final photo = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null && mounted) {
        setState(() => attachments.add(photo.path));
      }
    } catch (e) {
      showError('Unable to take photo: $e');
    }
  }

  Future<void> choosePhotos() async {
    try {
      final photos = await imagePicker.pickMultiImage(imageQuality: 80);

      if (mounted && photos.isNotEmpty) {
        setState(() {
          attachments.addAll(photos.map((e) => e.path));
        });
      }
    } catch (e) {
      showError('Unable to choose photos: $e');
    }
  }

  Future<void> attachFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );

      if (!mounted || result == null) return;

      final path = result.single.path;

      if (path != null) {
        setState(() => attachments.add(path));
      }
    } catch (e) {
      showError('Unable to attach file: $e');
    }
  }

  void showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> sendHandover() async {
    if (submitting) return;

    if (!answersSaved) {
      showError('Please complete the check sheet first');
      await openCheckSheet();
      return;
    }

    setState(() => submitting = true);

    // TODO: Send the note, answers, attachments and
    // handover details to your API here.

    if (!mounted) return;

    setState(() => submitting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HandoverSavedPage(data: widget.data)),
    );
  }

  Future<void> saveProgress() async {
    if (submitting || !_progressFormKey.currentState!.validate()) return;

    // TODO: Persist remainingController.text, attachments and draft state.
    showError('Progress kept for this session');
  }

  void onWorkNotReadyChanged(bool? value) {
    if (submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => workNotReady = value ?? false);
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
      appBar: CustomAppBar(
        title: workNotReady ? 'Save progress' : 'Hand over area',
        subtitle: widget.data.projectName,
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          handoverAreaHeading(context, widget.data),

          const SizedBox(height: 14),

          if (!workNotReady) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceColor(AppColors.surface),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.borderColor(AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Sending to',
                    style: TextStyle(color: Color(0xFFA7D3FF), fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    widget.data.receivingCompany,
                    style: TextStyle(
                      color: context.foregroundColor(AppColors.textPrimary),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Text(
              'Handing on check sheet',
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            InkWell(
              onTap: openCheckSheet,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: answersSaved
                      ? const Color(0xFF173C40)
                      : context.surfaceColor(AppColors.surface),
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
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF244A39),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assignment_turned_in_outlined,
                        color: context.accentColor(handoverAccent),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.data.checkSheetCode} · ${widget.data.checkSheetTitle}',
                            style: TextStyle(
                              color: context.foregroundColor(
                                AppColors.textPrimary,
                              ),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            answersSaved
                                ? 'Answers saved'
                                : 'Tap to complete check sheet',
                            style: TextStyle(
                              color: answersSaved
                                  ? context.accentColor(handoverAccent)
                                  : context.mutedColor(AppColors.textSecondary),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      answersSaved ? Icons.check : Icons.chevron_right,
                      color: context.accentColor(handoverAccent),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Note (optional)',
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: noteController,
              maxLines: 3,
              minLines: 3,
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 14,
              ),
              decoration: handoverInputDecoration(
                context,
                'Add anything the team should know.',
              ),
            ),

            const SizedBox(height: 9),
          ] else ...[
            Text(
              "What's left?",
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Form(
              key: _progressFormKey,
              child: TextFormField(
                controller: remainingController,
                minLines: 3,
                maxLines: 3,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please describe the remaining work'
                    : null,
                style: TextStyle(
                  color: context.foregroundColor(AppColors.textPrimary),
                ),
                decoration: handoverInputDecoration(
                  context,
                  'Say what work remains.',
                ),
              ),
            ),
            const SizedBox(height: 9),
          ],
          _buildAttachmentField(),

          const SizedBox(height: 16),

          Row(
            children: [
              Checkbox(
                value: workNotReady,
                activeColor: handoverAccent,
                checkColor: const Color(0xFF092537),
                onChanged: submitting ? null : onWorkNotReadyChanged,
              ),
              Text(
                'Work is not ready yet',
                style: TextStyle(
                  color: context.foregroundColor(AppColors.textPrimary),
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            workNotReady
                ? 'Only your progress is saved. The area stays with ${widget.data.companyName}.'
                : 'The area stays with the current company until the receiving company accepts.',
            style: TextStyle(color: Color(0xFFA7D3FF), fontSize: 12),
          ),
        ],
      ),
      bottomNavigationBar: handoverBottomButton(
        context,
        title: workNotReady
            ? 'Save progress'
            : (submitting ? 'Sending...' : 'Send handover'),
        onPressed: submitting
            ? null
            : (workNotReady ? saveProgress : sendHandover),
      ),
    );
  }

  Widget _buildAttachmentField() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              OutlinedButton.icon(
                onPressed: addAttachments,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: handoverOutlineStyle(context),
              ),
            ],
          ),
        ),
        ...attachments.map((path) {
          final fileName = path.split(RegExp(r'[/\\]')).last;

          return ListTile(
            dense: true,
            leading: const Icon(Icons.attach_file, color: Color(0xFFA7D3FF)),
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent),
              onPressed: () {
                setState(() => attachments.remove(path));
              },
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------
// CHECK SHEET SCREEN
// ---------------------------------------------

class HandoverCheckSheetPage extends StatefulWidget {
  const HandoverCheckSheetPage({
    super.key,
    required this.data,
    this.existingAnswers,
  });

  final HandoverAreaData data;
  final List<String>? existingAnswers;

  @override
  State<HandoverCheckSheetPage> createState() => _HandoverCheckSheetPageState();
}

class _HandoverCheckSheetPageState extends State<HandoverCheckSheetPage> {
  late List<String> answers;

  @override
  void initState() {
    super.initState();

    if (widget.existingAnswers != null &&
        widget.existingAnswers!.length == widget.data.questions.length) {
      answers = List<String>.from(widget.existingAnswers!);
    } else {
      answers = List<String>.filled(widget.data.questions.length, '');
    }
  }

  void saveAnswers() {
    if (answers.any((answer) => answer.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    Navigator.pop(context, List<String>.from(answers));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor(AppColors.background),
      appBar: CustomAppBar(
        title: 'Check sheet',
        subtitle: '${widget.data.checkSheetCode} · Taking over',
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Text(
            '${widget.data.activityCode} · ${widget.data.activityName}',
            style: TextStyle(
              color: context.accentColor(handoverAccent),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.data.checkSheetTitle,
            style: TextStyle(
              color: context.foregroundColor(AppColors.textPrimary),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            widget.data.area,
            style: const TextStyle(color: Color(0xFFA7D3FF), fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...List.generate(widget.data.questions.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.surfaceColor(AppColors.surface),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.borderColor(AppColors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.questions[index],
                    style: TextStyle(
                      color: context.foregroundColor(AppColors.textPrimary),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _answerButton(index, 'Yes', Icons.check),
                      const SizedBox(width: 5),
                      _answerButton(index, 'No', Icons.close),
                      const SizedBox(width: 5),
                      _answerButton(index, 'N/A', Icons.remove),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: handoverBottomButton(
        context,
        title: 'Save answers',
        icon: Icons.check,
        onPressed: saveAnswers,
      ),
    );
  }

  Widget _answerButton(int index, String answer, IconData icon) {
    final selected = answers[index] == answer;

    Color bg = context.backgroundColor(AppColors.background);
    Color fg = context.foregroundColor(AppColors.textPrimary);

    if (selected && answer == 'Yes') {
      bg = handoverAccent;
      fg = const Color(0xFF092537);
    } else if (selected && answer == 'No') {
      bg = const Color(0xFF573039);
    } else if (selected) {
      bg = const Color(0xFF315368);
    }

    return Expanded(
      child: SizedBox(
        height: 43,
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              answers[index] = answer;
            });
          },
          icon: Icon(icon, size: 15),
          label: Text(answer),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: bg,
            foregroundColor: fg,
            side: BorderSide(
              color: selected && answer == 'Yes'
                  ? context.accentColor(handoverAccent)
                  : context.borderColor(AppColors.border),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------
// SAVE PROGRESS SCREEN
// ---------------------------------------------

class SaveHandoverProgressPage extends StatefulWidget {
  const SaveHandoverProgressPage({super.key, required this.data});

  final HandoverAreaData data;

  @override
  State<SaveHandoverProgressPage> createState() =>
      _SaveHandoverProgressPageState();
}

class _SaveHandoverProgressPageState extends State<SaveHandoverProgressPage> {
  final remainingController = TextEditingController();
  bool workNotReady = true;

  @override
  void dispose() {
    remainingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor(AppColors.background),
      appBar: CustomAppBar(
        title: 'Save progress',
        subtitle: widget.data.projectName,
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          handoverAreaHeading(context, widget.data),
          const SizedBox(height: 22),
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
            maxLines: 3,
            minLines: 3,
            style: TextStyle(
              color: context.foregroundColor(AppColors.textPrimary),
            ),
            decoration: handoverInputDecoration(
              context,
              'Say what work remains.',
            ),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(10),
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
                OutlinedButton.icon(
                  onPressed: () {
                    // Add the same attachment picker used
                    // by HandOverAreaPage here.
                  },
                  style: handoverOutlineStyle(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          CheckboxListTile(
            value: workNotReady,
            contentPadding: EdgeInsets.zero,
            activeColor: handoverAccent,
            checkColor: const Color(0xFF092537),
            title: Text(
              'Work is not ready yet',
              style: TextStyle(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 12,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) {
              setState(() {
                workNotReady = value ?? false;
              });
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Only your progress is saved. The area stays with ${widget.data.companyName}.',
            style: const TextStyle(color: Color(0xFFA7D3FF), fontSize: 12),
          ),
        ],
      ),
      bottomNavigationBar: handoverBottomButton(
        context,
        title: 'Save progress',
        onPressed: () {
          // TODO: Save remaining work and draft state
          // to your local database or backend.
          Navigator.pop(context, true);
        },
      ),
    );
  }
}

// ---------------------------------------------
// HANDOVER SAVED SCREEN
// ---------------------------------------------

class HandoverSavedPage extends StatelessWidget {
  const HandoverSavedPage({super.key, required this.data});

  final HandoverAreaData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor(AppColors.background),
      appBar: CustomAppBar(title: 'Handover saved', subtitle: data.projectName),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 38, 12, 20),
        children: [
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF214536),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Icon(Icons.check, color: context.accentColor(handoverAccent), size: 28),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            'Handover sent',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.foregroundColor(AppColors.textPrimary),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Awaiting acceptance by ${data.receivingCompany}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA7D3FF), fontSize: 14),
          ),
          const SizedBox(height: 32),
          handoverAreaHeading(context, data),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context, 'view');
              },
              style: handoverOutlineStyle(context),
              icon: const Icon(Icons.chevron_right),
              label: const Text('View area'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: handoverBottomButton(
        context,
        title: 'Back to handovers',
        onPressed: () => Navigator.pop(context, 'sent'),
      ),
    );
  }
}
