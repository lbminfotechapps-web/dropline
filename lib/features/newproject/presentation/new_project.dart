import 'package:flutter/material.dart';

class NewProjectPage extends StatefulWidget {
  const NewProjectPage({super.key});

  @override
  State<NewProjectPage> createState() => _NewProjectPageState();
}

class _NewProjectPageState extends State<NewProjectPage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _lime = Color(0xFFB5FF65);
  final _formKey = GlobalKey<FormState>();
  final _project = TextEditingController(text: 'Laxmi Gauri');
  final _company = TextEditingController(text: 'Apex Build');
  bool _business = true;
  final _companyFocus = FocusNode();

  @override
  void dispose() {
    _project.dispose();
    _company.dispose();
    _companyFocus.dispose();
    super.dispose();
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
              double size = 6.5,
              Color color = _muted,
              bool bold = false,
            }) => Text(
              value,
              style: TextStyle(
                fontSize: size * s,
                color: color,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: .15 * s,
              ),
            );
            OutlineInputBorder border(Color color) => OutlineInputBorder(
              borderRadius: BorderRadius.circular(5 * s),
              borderSide: BorderSide(color: color),
            );
            Widget field(
              TextEditingController controller, {
              FocusNode? focus,
            }) => TextFormField(
              controller: controller,
              focusNode: focus,
              style: TextStyle(color: const Color(0xFFE4EFF5), fontSize: 7 * s),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6 * s,
                  vertical: 8 * s,
                ),
                filled: true,
                fillColor: _surface,
                enabledBorder: border(_border),
                focusedBorder: border(_muted),
                errorBorder: border(Colors.redAccent),
                focusedErrorBorder: border(Colors.redAccent),
              ),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 6 * s, 10 * s, 10 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 16 * s).clamp(
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
                              width: 20 * s,
                              height: 22 * s,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: const BorderSide(color: _border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6 * s),
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                child: Icon(
                                  Icons.chevron_left,
                                  color: _muted,
                                  size: 13 * s,
                                ),
                              ),
                            ),
                            SizedBox(width: 7 * s),
                            label(
                              'New project',
                              size: 12,
                              color: const Color(0xFFF0F4FC),
                              bold: true,
                            ),
                          ],
                        ),
                        SizedBox(height: 10 * s),
                        label('Business or personal'),
                        SizedBox(height: 10 * s),
                        Row(
                          children: [true, false]
                              .map(
                                (business) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: business ? 4 * s : 0,
                                    ),
                                    child: SizedBox(
                                      height: 20 * s,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          backgroundColor: _business == business
                                              ? _lime
                                              : _surface,
                                          side: BorderSide(
                                            color: _business == business
                                                ? _lime
                                                : _border,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6 * s,
                                            ),
                                          ),
                                        ),
                                        onPressed: () => setState(
                                          () => _business = business,
                                        ),
                                        child: label(
                                          business ? 'Business' : 'Personal',
                                          color: _business == business
                                              ? _background
                                              : _muted,
                                          bold: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        SizedBox(height: 10 * s),
                        label('Project name', bold: true),
                        SizedBox(height: 3 * s),
                        field(_project),
                        if (_business) ...[
                          SizedBox(height: 15 * s),
                          label('Your company', bold: true),
                          SizedBox(height: 3 * s),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 24 * s,
                                  alignment: Alignment.centerLeft,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6 * s,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _surface,
                                    border: Border.all(color: _border),
                                    borderRadius: BorderRadius.circular(5 * s),
                                  ),
                                  child: label(
                                    'Create a new company',
                                    color: const Color(0xFFE4EFF5),
                                    size: 7,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6 * s),
                              SizedBox(
                                width: 44 * s,
                                height: 24 * s,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    side: const BorderSide(color: _lime),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        6 * s,
                                      ),
                                    ),
                                  ),
                                  onPressed: _companyFocus.requestFocus,
                                  child: label(
                                    '+ New',
                                    color: _lime,
                                    bold: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10 * s),
                          label('New company name', bold: true),
                          SizedBox(height: 3 * s),
                          field(_company, focus: _companyFocus),
                          SizedBox(height: 16 * s),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7 * s,
                              vertical: 6 * s,
                            ),
                            decoration: BoxDecoration(
                              color: _surface.withValues(alpha: .6),
                              borderRadius: BorderRadius.circular(5 * s),
                            ),
                            child: label(
                              'Your role on this project: Company owner',
                            ),
                          ),
                          SizedBox(height: 24 * s),
                          label(
                            'An existing company can be selected by its name or\nDropline ID.',
                          ),
                        ],
                        SizedBox(height: 30 * s),
                        const Spacer(),
                        SizedBox(
                          height: 27 * s,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _lime,
                              foregroundColor: _background,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6 * s),
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.of(context).pop({
                                  'name': _project.text.trim(),
                                  'category': _business
                                      ? 'Business'
                                      : 'Personal',
                                  'company': _business
                                      ? _company.text.trim()
                                      : null,
                                });
                              }
                            },
                            child: label(
                              'Create project',
                              size: 7,
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
