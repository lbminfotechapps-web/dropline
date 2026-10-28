import 'package:flutter/material.dart';
import 'company_team_invitation.dart';

class InvitePeoplePage extends StatefulWidget {
  const InvitePeoplePage({super.key, this.onContacts});

  final VoidCallback? onContacts;

  @override
  State<InvitePeoplePage> createState() => _InvitePeoplePageState();
}

class _InvitePeoplePageState extends State<InvitePeoplePage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);

  final _formKey = GlobalKey<FormState>();
  final _people = [_PersonForm(name: 'Amit Desai')];

  @override
  void dispose() {
    for (final person in _people) {
      person.name.dispose();
      person.contact.dispose();
    }
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
                letterSpacing: .15 * s,
              ),
            );
            OutlineInputBorder border(Color color) => OutlineInputBorder(
              borderRadius: BorderRadius.circular(6 * s),
              borderSide: BorderSide(color: color),
            );
            InputDecoration decoration({String? hint}) => InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _surface,
              hintText: hint,
              hintStyle: TextStyle(color: _text, fontSize: 7 * s),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 7 * s,
                vertical: 7 * s,
              ),
              enabledBorder: border(_border),
              focusedBorder: border(_muted),
              errorBorder: border(Colors.redAccent),
              focusedErrorBorder: border(Colors.redAccent),
            );
            Widget field(
              TextEditingController controller, {
              bool phone = false,
            }) => TextFormField(
              controller: controller,
              keyboardType: phone ? TextInputType.phone : TextInputType.name,
              textCapitalization: phone
                  ? TextCapitalization.none
                  : TextCapitalization.words,
              style: TextStyle(color: _text, fontSize: 7 * s),
              decoration: decoration(hint: phone ? '+91 ****** 0027' : null),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            );
            Widget permission(
              _PersonForm person,
              int index,
              String title,
            ) => Container(
              height: 24 * s,
              margin: EdgeInsets.only(bottom: 4 * s),
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
                        value: person.permissions[index],
                        onChanged: (value) =>
                            setState(() => person.permissions[index] = value),
                        activeThumbColor: Colors.white,
                        activeTrackColor: _lime,
                        inactiveThumbColor: _text,
                        inactiveTrackColor: _border,
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
              padding: EdgeInsets.fromLTRB(10 * s, 6 * s, 10 * s, 8 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 14 * s).clamp(
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
                                'Invite people',
                                size: 12,
                                bold: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10 * s),
                        label(
                          'Laxmi Gauri · Apex Build',
                          size: 6.5,
                          color: _muted,
                        ),
                        for (final person in _people) ...[
                          SizedBox(height: 10 * s),
                          Row(
                            children: [
                              Expanded(
                                child: label(
                                  'Full name',
                                  size: 6.5,
                                  color: _muted,
                                  bold: true,
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    widget.onContacts ??
                                    () => ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Contact selection is not connected yet',
                                            ),
                                          ),
                                        ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: label(
                                  'Contacts',
                                  size: 6,
                                  color: _lime,
                                  bold: true,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3 * s),
                          field(person.name),
                          SizedBox(height: 8 * s),
                          label(
                            'Contact number',
                            size: 6.5,
                            color: _muted,
                            bold: true,
                          ),
                          SizedBox(height: 3 * s),
                          field(person.contact, phone: true),
                          SizedBox(height: 8 * s),
                          label('Role', size: 6.5, color: _muted, bold: true),
                          SizedBox(height: 3 * s),
                          DropdownButtonFormField<String>(
                            initialValue: person.role,
                            dropdownColor: _surface,
                            style: TextStyle(color: _text, fontSize: 7 * s),
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: _muted,
                              size: 12 * s,
                            ),
                            decoration: decoration(),
                            items: ['Admin', 'Member']
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ),
                                )
                                .toList(),
                            onChanged: (role) => setState(
                              () => person.role = role ?? person.role,
                            ),
                          ),
                          SizedBox(height: 16 * s),
                          label('Project permissions', size: 8, bold: true),
                          SizedBox(height: 4 * s),
                          label(
                            person.role == 'Admin'
                                ? 'Admin includes own team and handovers.'
                                : 'Choose permissions for this team member.',
                            size: 6,
                            color: _muted,
                          ),
                          SizedBox(height: 7 * s),
                          permission(person, 0, 'Manage companies'),
                          permission(person, 1, 'Manage areas'),
                          permission(person, 2, 'Manage events'),
                          permission(person, 3, 'Manage flows'),
                        ],
                        SizedBox(height: 10 * s),
                        TextButton(
                          onPressed: () =>
                              setState(() => _people.add(_PersonForm())),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 5 * s),
                          ),
                          child: label(
                            '+ Add another person',
                            color: _lime,
                            bold: true,
                          ),
                        ),
                        SizedBox(height: 15 * s),
                        const Spacer(),
                        SizedBox(
                          height: 27 * s,
                          child: FilledButton(
                            onPressed: () {
                              if (!_formKey.currentState!.validate()) return;
                              final members = [
                                const CompanyTeamMember(
                                  name: 'Rahul Sharma',
                                  role: 'Admin',
                                  joined: true,
                                ),
                                ..._people.map(
                                  (person) => CompanyTeamMember(
                                    name: person.name.text.trim(),
                                    role: person.role,
                                  ),
                                ),
                              ];
                              Navigator.of(context).pushReplacement<void, void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => CompanyTeamInvitationPage(
                                    members: members,
                                  ),
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
                              'Send invitation',
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

class _PersonForm {
  _PersonForm({String name = ''}) : name = TextEditingController(text: name);

  final TextEditingController name;
  final contact = TextEditingController();
  String role = 'Admin';
  final permissions = [true, true, false, true];
}
