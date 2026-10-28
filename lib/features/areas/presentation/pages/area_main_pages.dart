import 'package:dropline/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:dropline/core/theme/app_text_styles.dart';

class AreaMainPage extends StatefulWidget {
  const AreaMainPage({
    super.key,
    this.projectName = 'Laxmi Gauri',
    this.initialLabels,
    this.initialAboutAreas,
    this.returnResult = false,
  });

  final String projectName;
  final List<String>? initialLabels;
  final String? initialAboutAreas;
  final bool returnResult;

  @override
  State<AreaMainPage> createState() => _AreaMainPageState();
}

class _AreaMainPageState extends State<AreaMainPage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _foreground = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;
  late final TextEditingController _aboutController;

  @override
  void initState() {
    super.initState();
    _aboutController = TextEditingController(
      text:
          widget.initialAboutAreas ??
          'Areas help you organise work by place. Use names that suit your workplace, e.g. Building → Floor → Room, Plant → Line → Machine, or Warehouse → Aisle → Rack. Rename the labels and use only the detail you need. This keeps photos, notes, drawings and handovers linked to the right place, helping your team find records and follow progress.',
    );
    const defaults = ['Building', 'Level', 'Apartment', 'Room'];
    _controllers = List.generate(
      4,
      (index) => TextEditingController(
        text:
            widget.initialLabels != null && index < widget.initialLabels!.length
            ? widget.initialLabels![index]
            : defaults[index],
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _aboutController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final result = <String, dynamic>{
      'labels': _controllers
          .map((controller) => controller.text.trim())
          .toList(),
      'aboutAreas': _aboutController.text.trim(),
    };
    if (widget.returnResult) {
      context.pop(result);
    } else {
      context.push(
        Uri(
          path: AppRouter.areas,
          queryParameters: {'projectName': widget.projectName},
        ).toString(),
        extra: result,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = (constraints.maxWidth / 262).clamp(1.0, 1.6);
            TextStyle style(
              double size, {
              bool bold = false,
              Color color = _muted,
            }) => AppTextStyles.bodySmall.copyWith(
              fontSize: size * s,
              color: color,
              height: 1.25,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 0.1 * s,
            );
            Widget field(int index, String title, String example) => Padding(
              padding: EdgeInsets.only(bottom: 9 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: style(9, bold: true)),
                  SizedBox(height: 4 * s),
                  Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      border: Border.all(color: _border, width: 0.7),
                      borderRadius: BorderRadius.circular(9 * s),
                    ),
                    padding: EdgeInsets.fromLTRB(8 * s, 3 * s, 8 * s, 5 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _controllers[index],
                          style: style(10, color: _foreground),
                          cursorColor: _lime,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: index == 3
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onFieldSubmitted: index == 3 ? (_) => _save() : null,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a label'
                              : null,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 3 * s,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            errorStyle: style(8, color: Colors.redAccent),
                          ),
                        ),
                        Text(example, style: style(7)),
                      ],
                    ),
                  ),
                ],
              ),
            );
            return Padding(
              padding: EdgeInsets.fromLTRB(13 * s, 6 * s, 13 * s, 7 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 27 * s,
                        height: 28 * s,
                        child: OutlinedButton(
                          onPressed: () {
                            if (context.canPop()) context.pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: _muted,
                            backgroundColor: _surface,
                            side: const BorderSide(color: _border, width: 0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8 * s),
                            ),
                          ),
                          child: Semantics(
                            label: 'Back to project setup',
                            child: Icon(Icons.chevron_left, size: 16 * s),
                          ),
                        ),
                      ),
                      SizedBox(width: 9 * s),
                      Expanded(
                        child: Text(
                          'Area labels',
                          style: style(15, bold: true, color: _foreground),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * s),
                  Text(widget.projectName, style: style(8)),
                  SizedBox(height: 14 * s),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            field(
                              0,
                              'Main area label',
                              'e.g. Building, Phase, Road, Factory, Tunnel',
                            ),
                            field(
                              1,
                              'Sub-area label',
                              'e.g. Level, Block, Stretch, Processing area, Bore',
                            ),
                            field(
                              2,
                              'Location label',
                              'e.g. Apartment, Plot, Chainage, Line, Ring',
                            ),
                            field(
                              3,
                              'Specific location label',
                              'e.g. Room, Area, Lane, Machine, Segment',
                            ),
                            SizedBox(height: 5 * s),
                            Text(
                              'Use labels that fit this project. The saved parent-child links stay the same.',
                              style: style(8),
                            ),
                            SizedBox(height: 9 * s),
                            Container(
                              padding: EdgeInsets.all(9 * s),
                              decoration: BoxDecoration(
                                color: _surface,
                                border: Border.all(color: _border, width: 0.7),
                                borderRadius: BorderRadius.circular(9 * s),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'About areas',
                                    style: style(
                                      9,
                                      bold: true,
                                      color: _foreground,
                                    ),
                                  ),
                                  SizedBox(height: 6 * s),
                                  TextFormField(
                                    controller: _aboutController,
                                    minLines: 5,
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    style: style(8),
                                    cursorColor: _lime,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      hintText: 'Describe how areas are used',
                                      semanticCounterText: 'About areas',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12 * s),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * s),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _lime,
                      foregroundColor: _background,
                      minimumSize: Size.fromHeight(34 * s),
                      padding: EdgeInsets.symmetric(vertical: 10 * s),
                      textStyle: style(10, bold: true, color: _background),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9 * s),
                      ),
                    ),
                    child: const Text('Save labels'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
