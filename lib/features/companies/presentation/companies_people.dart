import 'package:flutter/material.dart';

class CompaniesPeoplePage extends StatefulWidget {
  const CompaniesPeoplePage({super.key});

  @override
  State<CompaniesPeoplePage> createState() => _CompaniesPeoplePageState();
}

class _CompaniesPeoplePageState extends State<CompaniesPeoplePage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);

  bool _showCompanies = true;
  final List<String> _companies = ['Apex Build'];

  Future<void> _addCompany() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Add company', style: TextStyle(color: _text)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: _text),
          decoration: const InputDecoration(
            labelText: 'Company name',
            labelStyle: TextStyle(color: _muted),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Add', style: TextStyle(color: _lime)),
          ),
        ],
      ),
    );
    // Let the dialog finish its dismissal animation before disposing its field.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (!mounted || name == null) return;
    setState(() => _companies.add(name));
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
            ButtonStyle buttonStyle({bool selected = false}) =>
                OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: selected ? _lime : _surface,
                  side: BorderSide(color: selected ? _lime : _border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7 * s),
                  ),
                );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 9 * s, 10 * s, 16 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 21 * s,
                        height: 22 * s,
                        child: OutlinedButton(
                          style: buttonStyle(),
                          onPressed: () => Navigator.of(context).maybePop(),
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
                          'Companies & people',
                          size: 12,
                          bold: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * s),
                  label('Laxmi Gauri · Apex Build', size: 6.5, color: _muted),
                  SizedBox(height: 11 * s),
                  Row(
                    children: [true, false]
                        .map(
                          (companies) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: companies ? 4 * s : 0,
                              ),
                              child: SizedBox(
                                height: 20 * s,
                                child: OutlinedButton(
                                  style: buttonStyle(
                                    selected: _showCompanies == companies,
                                  ),
                                  onPressed: () => setState(
                                    () => _showCompanies = companies,
                                  ),
                                  child: label(
                                    companies ? 'Companies' : 'Owner’s team',
                                    size: 6.5,
                                    bold: true,
                                    color: _showCompanies == companies
                                        ? _background
                                        : _muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 7 * s),
                  if (_showCompanies) ...[
                    for (final company in _companies)
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
                            label(company, size: 8, bold: true),
                            SizedBox(height: 2 * s),
                            label(
                              company == 'Apex Build'
                                  ? 'Your company · Suresh · Company owner'
                                  : 'Your company',
                              size: 6.5,
                              color: _muted,
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: 28 * s,
                      child: OutlinedButton(
                        style: buttonStyle(),
                        onPressed: _addCompany,
                        child: label('+ Add company', bold: true),
                      ),
                    ),
                  ] else
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12 * s),
                      child: label('No team members yet', color: _muted),
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
