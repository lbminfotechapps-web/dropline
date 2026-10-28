import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectEventCategory {
  const ProjectEventCategory({required this.name, required this.events});

  final String name;
  final List<String> events;
}

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key, this.projectName = 'Laxmi Gauri'});

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
  static const _lime = Color(0xFFB5FF65);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Quality');
  final _events = TextEditingController(
    text: 'Workmanship issue\nDrawing mismatch',
  );

  List<String> get _eventLines => _events.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

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
      _events.text = data!.text!;
      _events.selection = TextSelection.collapsed(offset: _events.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = constraints.maxWidth / 210;
            Text label(
              String value, {
              double size = 7,
              Color color = _text,
              bool bold = false,
            }) => Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: size * s,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
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
              fillColor: _surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 7 * s,
                vertical: 7 * s,
              ),
              enabledBorder: border(_border),
              focusedBorder: border(_muted),
              errorBorder: border(Colors.redAccent),
              focusedErrorBorder: border(Colors.redAccent),
            );
            ButtonStyle outline() => OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: _surface,
              side: const BorderSide(color: _border),
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
                                  color: _muted,
                                  size: 13 * s,
                                ),
                              ),
                            ),
                            SizedBox(width: 7 * s),
                            Expanded(
                              child: label(
                                'New category',
                                size: 12,
                                bold: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10 * s),
                        label(widget.projectName, size: 6.5, color: _muted),
                        SizedBox(height: 11 * s),
                        label(
                          'Category name',
                          size: 6.5,
                          color: _muted,
                          bold: true,
                        ),
                        SizedBox(height: 3 * s),
                        TextFormField(
                          controller: _name,
                          style: TextStyle(color: _text, fontSize: 7 * s),
                          textCapitalization: TextCapitalization.words,
                          decoration: decoration(),
                          onChanged: (_) => setState(() {}),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a category name'
                              : null,
                        ),
                        SizedBox(height: 12 * s),
                        Row(
                          children: [
                            Expanded(
                              child: label(
                                'Events · one per line',
                                size: 6.5,
                                color: _muted,
                                bold: true,
                              ),
                            ),
                            SizedBox(
                              width: 43 * s,
                              height: 24 * s,
                              child: OutlinedButton(
                                onPressed: _paste,
                                style: outline(),
                                child: label(
                                  'Paste',
                                  size: 6.5,
                                  color: _lime,
                                  bold: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7 * s),
                        TextFormField(
                          controller: _events,
                          minLines: 8,
                          maxLines: 8,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            color: _text,
                            fontSize: 7 * s,
                            height: 2.6,
                          ),
                          decoration: decoration(),
                          onChanged: (_) => setState(() {}),
                          validator: (_) => _eventLines.isEmpty
                              ? 'Enter at least one event'
                              : null,
                        ),
                        SizedBox(height: 20 * s),
                        label(
                          '${_name.text.trim().isEmpty ? 0 : 1} category · ${_eventLines.length} ${_eventLines.length == 1 ? 'event' : 'events'}',
                          size: 8,
                          color: _lime,
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
                              backgroundColor: _lime,
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
