import 'package:flutter/material.dart';
import 'invitation_ready.dart';

class InviteCompanyAdminPage extends StatefulWidget {
  const InviteCompanyAdminPage({
    super.key,
    this.companyName = 'PlasterCo',
    this.projectName = 'Laxmi Gauri',
  });

  final String companyName;
  final String projectName;

  @override
  State<InviteCompanyAdminPage> createState() => _InviteCompanyAdminPageState();
}

class _InviteCompanyAdminPageState extends State<InviteCompanyAdminPage> {
  static const _background = Color(0xFF03283B);
  static const _surface = Color(0xFF0B2E44);
  static const _border = Color(0xFF264C63);
  static const _muted = Color(0xFF80B2CD);
  static const _text = Color(0xFFE9F2F8);
  static const _lime = Color(0xFFB5FF65);
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Rahul Sharma');
  final _mobile = TextEditingController();
  final _permissions = [true, true, true];

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
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
                color: color,
                fontSize: size * s,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            );
            BoxDecoration panel() => BoxDecoration(
              color: _surface,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(5 * s),
            );
            OutlineInputBorder border(Color color) => OutlineInputBorder(
              borderRadius: BorderRadius.circular(5 * s),
              borderSide: BorderSide(color: color),
            );
            Widget field(
              String title,
              TextEditingController controller, {
              bool phone = false,
            }) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                label(title, size: 6.5, color: _muted),
                SizedBox(height: 3 * s),
                TextFormField(
                  controller: controller,
                  keyboardType: phone
                      ? TextInputType.phone
                      : TextInputType.name,
                  textCapitalization: phone
                      ? TextCapitalization.none
                      : TextCapitalization.words,
                  style: TextStyle(color: _text, fontSize: 8 * s),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                  decoration: InputDecoration(
                    hintText: phone ? '+91  •••••••• 0042' : null,
                    hintStyle: TextStyle(color: _text, fontSize: 8 * s),
                    filled: true,
                    fillColor: _surface,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8 * s,
                      vertical: 8 * s,
                    ),
                    enabledBorder: border(_border),
                    focusedBorder: border(_muted),
                    errorBorder: border(Colors.redAccent),
                    focusedErrorBorder: border(Colors.redAccent),
                  ),
                ),
              ],
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 8 * s, 10 * s, 18 * s),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 22 * s,
                          height: 22 * s,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: const BorderSide(color: _border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5 * s),
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              color: _muted,
                              size: 12 * s,
                            ),
                          ),
                        ),
                        SizedBox(width: 8 * s),
                        Expanded(
                          child: label(
                            'Invite company admin',
                            size: 12,
                            bold: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * s),
                    Container(
                      padding: EdgeInsets.all(8 * s),
                      decoration: panel(),
                      child: Row(
                        children: [
                          Icon(
                            Icons.apartment_outlined,
                            color: _muted,
                            size: 19 * s,
                          ),
                          SizedBox(width: 10 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                label(widget.companyName, size: 8, bold: true),
                                SizedBox(height: 2 * s),
                                label(
                                  widget.projectName,
                                  size: 6.5,
                                  color: _muted,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 11 * s),
                    field('Full name', _name),
                    SizedBox(height: 11 * s),
                    field('Mobile number', _mobile, phone: true),
                    SizedBox(height: 11 * s),
                    label('Role', size: 6.5, color: _muted),
                    SizedBox(height: 3 * s),
                    DropdownButtonFormField<String>(
                      initialValue: 'Company admin',
                      dropdownColor: _surface,
                      style: TextStyle(color: _text, fontSize: 8 * s),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: _muted,
                        size: 13 * s,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: _muted,
                          size: 14 * s,
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 29 * s),
                        isDense: true,
                        filled: true,
                        fillColor: _surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 7 * s,
                          vertical: 8 * s,
                        ),
                        enabledBorder: border(_border),
                        focusedBorder: border(_muted),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Company admin',
                          child: Text('Company admin'),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                    SizedBox(height: 11 * s),
                    Container(
                      padding: EdgeInsets.all(11 * s),
                      decoration: panel(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          label(
                            'Can manage ${widget.companyName}',
                            size: 10,
                            bold: true,
                          ),
                          SizedBox(height: 4 * s),
                          for (final entry in [
                            'Add and manage its team',
                            'Set team handover access',
                            'Send and respond to handovers',
                          ].asMap().entries)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4 * s),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: label(
                                      entry.value,
                                      size: 7,
                                      color: _muted,
                                    ),
                                  ),
                                  SizedBox(width: 6 * s),
                                  SizedBox(
                                    width: 25 * s,
                                    height: 16 * s,
                                    child: FittedBox(
                                      child: Switch(
                                        value: _permissions[entry.key],
                                        onChanged: (value) => setState(
                                          () => _permissions[entry.key] = value,
                                        ),
                                        activeThumbColor: Colors.white,
                                        activeTrackColor: _lime,
                                        inactiveThumbColor: _text,
                                        inactiveTrackColor: _border,
                                        trackOutlineColor:
                                            const WidgetStatePropertyAll(
                                              Colors.transparent,
                                            ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Divider(color: _border, height: 17 * s),
                          label(
                            'Access is for ${widget.companyName} on this project.',
                            size: 6.5,
                            color: _muted,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15 * s),
                    SizedBox(
                      height: 28 * s,
                      child: FilledButton(
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;
                          final adminName = _name.text.trim();
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => InvitationReadyPage(
                                adminName: adminName,
                                companyName: widget.companyName,
                                projectName: widget.projectName,
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: _lime,
                          foregroundColor: _background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5 * s),
                          ),
                        ),
                        child: label(
                          'Create invite',
                          size: 8,
                          color: _background,
                          bold: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
