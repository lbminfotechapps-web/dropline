import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectEventCategory {
  const ProjectEventCategory({required this.name, required this.events});

  final String name;
  final List<String> events;
}

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({
    super.key,
    this.projectName = 'Laxmi Gauri',
    this.initialCategory,
    this.existingCategoryNames = const [],
  });

  final ProjectEventCategory? initialCategory;
  final List<String> existingCategoryNames;

  final String projectName;

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _primaryAccent = AppColors.primary;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _events;

  @override
  void initState() {
    super.initState();
    final category = widget.initialCategory;
    _name = TextEditingController(text: category?.name ?? '');
    _events = TextEditingController(
      text: _NumberedEventsFormatter.number(category?.events.join('\n') ?? ''),
    );
  }

  List<String> get _eventLines => _events.text
      .split('\n')
      .map(_NumberedEventsFormatter.content)
      .where((line) => line.isNotEmpty)
      .toList();

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter a category name';
    String normalize(String text) =>
        text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (widget.existingCategoryNames.any(
      (existing) => normalize(existing) == normalize(name),
    )) {
      return 'A category with this name already exists';
    }
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    _events.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || data?.text == null) return;
    setState(() {
      _events.text = _NumberedEventsFormatter.number(data!.text!);
      _events.selection = TextSelection.collapsed(offset: _events.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor(_background),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = constraints.maxWidth / 210;
            Text label(
              String value, {
              double size = 7,
              Color? color,
              bool bold = false,
            }) => Text(
              value,
              style: TextStyle(
                color: color ?? context.foregroundColor(_text),
                fontSize: size * s,
                fontWeight: bold ? FontWeight.w500 : FontWeight.w500,
                letterSpacing: .15 * s,
              ),
            );
            OutlineInputBorder border(Color color) => OutlineInputBorder(
              borderRadius: BorderRadius.circular(6 * s),
              borderSide: BorderSide(color: color),
            );
            InputDecoration decoration() => InputDecoration(
              isDense: true,
              filled: true,
              fillColor: context.surfaceColor(_surface),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 7 * s,
                vertical: 7 * s,
              ),
              enabledBorder: border(context.borderColor(_border)),
              focusedBorder: border(context.mutedColor(_muted)),
              errorBorder: border(Colors.redAccent),
              focusedErrorBorder: border(Colors.redAccent),
            );
            ButtonStyle outline() => OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: context.surfaceColor(_surface),
              side: BorderSide(color: context.borderColor(_border)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6 * s),
              ),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 3 * s, 10 * s, 10 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 13 * s).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 21 * s,
                              height: 22 * s,
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                style: outline(),
                                child: Icon(
                                  Icons.chevron_left,
                                  color: context.mutedColor(_muted),
                                  size: 13 * s,
                                ),
                              ),
                            ),
                            SizedBox(width: 7 * s),
                            Expanded(
                              child: label(
                                widget.initialCategory == null
                                    ? 'New category'
                                    : 'Edit category',
                                size: 12,
                                bold: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10 * s),
                        label(
                          widget.projectName,
                          size: 6.5,
                          color: context.mutedColor(_muted),
                        ),
                        SizedBox(height: 11 * s),
                        label(
                          'Category name',
                          size: 6.5,
                          color: context.mutedColor(_muted),
                          bold: true,
                        ),
                        SizedBox(height: 3 * s),
                        TextFormField(
                          controller: _name,
                          style: TextStyle(
                            color: context.foregroundColor(_text),
                            fontSize: 7 * s,
                          ),
                          textCapitalization: TextCapitalization.words,
                          decoration: decoration(),
                          onChanged: (_) => setState(() {}),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: _validateName,
                        ),
                        SizedBox(height: 12 * s),
                        Row(
                          children: [
                            Expanded(
                              child: label(
                                'Events · one per line',
                                size: 6.5,
                                color: context.mutedColor(_muted),
                                bold: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7 * s),
                        TextFormField(
                          controller: _events,
                          inputFormatters: [_NumberedEventsFormatter()],
                          textInputAction: TextInputAction.newline,
                          minLines: 8,
                          maxLines: 8,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            color: context.foregroundColor(_text),
                            fontSize: 7 * s,
                            height: 2.6,
                          ),
                          decoration: decoration(),
                          onChanged: (_) => setState(() {}),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (_) => _eventLines.isEmpty
                              ? 'Enter at least one event'
                              : null,
                        ),
                        SizedBox(height: 20 * s),
                        label(
                          '${_name.text.trim().isEmpty ? 0 : 1} category · ${_eventLines.length} ${_eventLines.length == 1 ? 'event' : 'events'}',
                          size: 8,
                          color: _primaryAccent,
                          bold: true,
                        ),
                        SizedBox(height: 20 * s),
                        const Spacer(),
                        SizedBox(
                          height: 27 * s,
                          child: FilledButton(
                            onPressed: () {
                              if (!_formKey.currentState!.validate()) return;
                              Navigator.of(context).pop(
                                ProjectEventCategory(
                                  name: _name.text.trim(),
                                  events: _eventLines,
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: _primaryAccent,
                              foregroundColor: _background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7 * s),
                              ),
                            ),
                            child: label(
                              'Save category & events',
                              color: _background,
                              bold: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NumberedEventsFormatter extends TextInputFormatter {
  static final _prefix = RegExp(r'^\s*\d+\.\s*');

  static String content(String line) => line.replaceFirst(_prefix, '').trim();

  static String number(String text) => text
      .split('\n')
      .indexed
      .map((entry) {
        return '${entry.$1 + 1}. ${entry.$2.replaceFirst(_prefix, '')}';
      })
      .join('\n');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final lines = newValue.text.split('\n');
    final numbered = number(newValue.text);
    int offset(int position) {
      if (position < 0) return numbered.length;
      var originalStart = 0;
      var numberedStart = 0;
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final removed = _prefix.firstMatch(line)?.end ?? 0;
        final prefixLength = '${index + 1}. '.length;
        final lineLength = prefixLength + line.length - removed;
        if (position <= originalStart + line.length) {
          return numberedStart +
              prefixLength +
              (position - originalStart - removed).clamp(
                0,
                line.length - removed,
              );
        }
        originalStart += line.length + 1;
        numberedStart += lineLength + 1;
      }
      return numbered.length;
    }

    return newValue.copyWith(
      text: numbered,
      selection: TextSelection(
        baseOffset: offset(newValue.selection.baseOffset),
        extentOffset: offset(newValue.selection.extentOffset),
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
      composing: TextRange.empty,
    );
  }
}
