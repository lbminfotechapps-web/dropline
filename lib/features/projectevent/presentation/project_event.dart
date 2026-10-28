import 'package:flutter/material.dart';

class ProjectEventPage extends StatefulWidget {
  const ProjectEventPage({
    super.key,
    this.projectName = 'Laxmi Gauri',
    this.companyName = 'Apex Build',
  });

  final String projectName;
  final String companyName;

  @override
  State<ProjectEventPage> createState() => _ProjectEventPageState();
}

class _ProjectEventPageState extends State<ProjectEventPage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);

  final _categories = <({String name, String events})>[
    (name: 'Quality', events: 'Workmanship issue · Drawing mismatch'),
    (name: 'Safety', events: 'Trip hazard'),
    (name: 'Progress', events: 'Work completed'),
  ];

  Future<void> _newCategory() async {
    final formKey = GlobalKey<FormState>();
    var name = '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('New category', style: TextStyle(color: _text)),
        content: Form(
          key: formKey,
          child: TextFormField(
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: _text),
            decoration: const InputDecoration(
              labelText: 'Category name',
              labelStyle: TextStyle(color: _muted),
            ),
            onChanged: (value) => name = value.trim(),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a category name'
                : null,
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, name);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Add', style: TextStyle(color: _lime)),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _categories.add((name: result, events: 'No events yet')));
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
            ButtonStyle outline() => OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: _surface,
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7 * s),
              ),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 7 * s, 10 * s, 9 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 16 * s).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 21 * s,
                            height: 22 * s,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).maybePop(),
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
                            child: label('Events', size: 12, bold: true),
                          ),
                        ],
                      ),
                      SizedBox(height: 10 * s),
                      label(
                        '${widget.projectName} · ${widget.companyName}',
                        size: 6.5,
                        color: _muted,
                      ),
                      SizedBox(height: 11 * s),
                      for (final category in _categories)
                        Container(
                          margin: EdgeInsets.only(bottom: 5 * s),
                          padding: EdgeInsets.symmetric(
                            horizontal: 7 * s,
                            vertical: 6 * s,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(7 * s),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(category.name, size: 8, bold: true),
                              SizedBox(height: 2 * s),
                              label(category.events, size: 6, color: _muted),
                            ],
                          ),
                        ),
                      SizedBox(
                        height: 28 * s,
                        child: OutlinedButton(
                          onPressed: _newCategory,
                          style: outline(),
                          child: label('+ New category', bold: true),
                        ),
                      ),
                      SizedBox(height: 20 * s),
                      const Spacer(),
                      SizedBox(
                        height: 27 * s,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: _lime,
                            foregroundColor: _background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7 * s),
                            ),
                          ),
                          child: label(
                            'Back to setup',
                            color: _background,
                            bold: true,
                          ),
                        ),
                      ),
                    ],
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
