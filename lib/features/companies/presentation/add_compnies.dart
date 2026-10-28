import 'package:flutter/material.dart';
import 'share_invitation.dart';

class AddCompaniesPage extends StatefulWidget {
  const AddCompaniesPage({super.key});

  @override
  State<AddCompaniesPage> createState() => _AddCompaniesPageState();
}

class _AddCompaniesPageState extends State<AddCompaniesPage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);

  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController(text: 'PlasterCo');
  final _admin = TextEditingController(text: 'Rahul Sharma');
  final _contact = TextEditingController();
  bool _sendHandovers = true;
  bool _reviewHandovers = true;

  @override
  void dispose() {
    _company.dispose();
    _admin.dispose();
    _contact.dispose();
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
              double size = 7,
              Color color = _text,
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
              borderRadius: BorderRadius.circular(6 * s),
              borderSide: BorderSide(color: color),
            );
            Widget field(
              String title,
              TextEditingController controller, {
              bool phone = false,
            }) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                label(title, size: 6.5, color: _muted, bold: true),
                SizedBox(height: 3 * s),
                TextFormField(
                  controller: controller,
                  keyboardType: phone
                      ? TextInputType.phone
                      : TextInputType.text,
                  textCapitalization: phone
                      ? TextCapitalization.none
                      : TextCapitalization.words,
                  style: TextStyle(color: _text, fontSize: 7 * s),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                  onChanged: phone ? null : (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: phone ? '+91 ****** 0042' : null,
                    hintStyle: TextStyle(color: _text, fontSize: 7 * s),
                    isDense: true,
                    filled: true,
                    fillColor: _surface,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6 * s,
                      vertical: 7 * s,
                    ),
                    enabledBorder: border(_border),
                    focusedBorder: border(_muted),
                    errorBorder: border(Colors.redAccent),
                    focusedErrorBorder: border(Colors.redAccent),
                  ),
                ),
              ],
            );
            Widget permission(
              String title,
              bool value,
              ValueChanged<bool> onChanged,
            ) => Container(
              height: 24 * s,
              padding: EdgeInsets.symmetric(horizontal: 7 * s),
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(6 * s),
              ),
              child: Row(
                children: [
                  Expanded(child: label(title, bold: true)),
                  SizedBox(
                    width: 21 * s,
                    height: 14 * s,
                    child: FittedBox(
                      child: Switch(
                        value: value,
                        onChanged: onChanged,
                        activeThumbColor: Colors.white,
                        activeTrackColor: _lime,
                        inactiveThumbColor: _muted,
                        inactiveTrackColor: _background,
                        trackOutlineColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 7 * s, 10 * s, 10 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 17 * s).clamp(
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
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: _surface,
                                  side: const BorderSide(color: _border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6 * s),
                                  ),
                                ),
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
                                'Add company & Admin',
                                size: 12,
                                bold: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10 * s),
                        label('Laxmi Gauri', size: 6.5, color: _muted),
                        SizedBox(height: 11 * s),
                        field('Company name or Dropline ID', _company),
                        SizedBox(height: 2 * s),
                        Padding(
                          padding: EdgeInsets.only(left: 6 * s),
                          child: label(
                            'New company · create with this invitation',
                            size: 5.5,
                            color: _lime,
                          ),
                        ),
                        SizedBox(height: 9 * s),
                        field('Admin’s full name', _admin),
                        SizedBox(height: 8 * s),
                        field('Contact number', _contact, phone: true),
                        SizedBox(height: 16 * s),
                        label(
                          'Role: Admin · ${_company.text.trim()}',
                          size: 8,
                          bold: true,
                        ),
                        SizedBox(height: 4 * s),
                        label(
                          'Can manage ${_company.text.trim()}’s project team.',
                          size: 6.5,
                          color: _muted,
                        ),
                        SizedBox(height: 12 * s),
                        permission(
                          'Send handovers',
                          _sendHandovers,
                          (value) => setState(() => _sendHandovers = value),
                        ),
                        SizedBox(height: 4 * s),
                        permission(
                          'Review handovers',
                          _reviewHandovers,
                          (value) => setState(() => _reviewHandovers = value),
                        ),
                        SizedBox(height: 18 * s),
                        label(
                          'Permissions apply to this company only.',
                          size: 6.5,
                          color: _muted,
                        ),
                        SizedBox(height: 20 * s),
                        const Spacer(),
                        SizedBox(
                          height: 27 * s,
                          child: FilledButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.of(
                                  context,
                                ).pushReplacement<String, String>(
                                  MaterialPageRoute<String>(
                                    builder: (_) => ShareInvitationPage(
                                      companyName: _company.text.trim(),
                                      adminName: _admin.text.trim(),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _lime,
                              foregroundColor: _background,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7 * s),
                              ),
                            ),
                            child: label(
                              'Add & send invitation',
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
