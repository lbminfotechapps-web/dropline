import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'invite_people.dart';
import 'start_work.dart';

class CompanyTeamMember {
  const CompanyTeamMember({
    required this.name,
    this.role = 'Team member',
    this.joined = false,
  });

  final String name;
  final String role;
  final bool joined;
}

class CompanyTeamInvitationPage extends StatelessWidget {
  const CompanyTeamInvitationPage({
    super.key,
    this.projectName = 'Laxmi Gauri',
    this.companyName = 'PlasterCo',
    this.members = const [
      CompanyTeamMember(name: 'Rahul Sharma', role: 'Admin', joined: true),
      CompanyTeamMember(name: 'Manoj Kumar'),
    ],
  });

  final String projectName;
  final String companyName;
  final List<CompanyTeamMember> members;

  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);

  Future<void> _share(BuildContext context, CompanyTeamMember member) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            '${member.name}, you are invited to $companyName on $projectName as ${member.role}.',
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invitation details copied')));
  }

  @override
  Widget build(BuildContext context) {
    final invited = members.where((member) => !member.joined).toList();
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
              padding: EdgeInsets.fromLTRB(10 * s, 7 * s, 10 * s, 10 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 17 * s).clamp(
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
                            child: label('Company team', size: 12, bold: true),
                          ),
                        ],
                      ),
                      SizedBox(height: 10 * s),
                      label(
                        '$projectName · $companyName',
                        size: 6.5,
                        color: _muted,
                      ),
                      SizedBox(height: 11 * s),
                      for (final member in members)
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
                              label(member.name, size: 8, bold: true),
                              SizedBox(height: 2 * s),
                              label(
                                '${member.role} · ${member.joined ? 'Joined' : 'Invited'}',
                                size: 6,
                                color: _muted,
                              ),
                            ],
                          ),
                        ),
                      for (final member in invited) ...[
                        SizedBox(
                          height: 28 * s,
                          child: OutlinedButton(
                            onPressed: () => _share(context, member),
                            style: outline(),
                            child: label(
                              'Share ${member.name.split(' ').first}’s invitation',
                              bold: true,
                            ),
                          ),
                        ),
                        SizedBox(height: 7 * s),
                      ],
                      SizedBox(
                        height: 28 * s,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pushReplacement<void, void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const InvitePeoplePage(),
                                ),
                              ),
                          style: outline(),
                          child: label('+ Invite people', bold: true),
                        ),
                      ),
                      SizedBox(height: 20 * s),
                      const Spacer(),
                      SizedBox(
                        height: 27 * s,
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(context).pushReplacement<void, void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => StartWorkPage(
                                    projectName: projectName,
                                    companyName: companyName,
                                  ),
                                ),
                              ),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: _lime,
                            foregroundColor: _background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7 * s),
                            ),
                          ),
                          child: label(
                            'Back to project',
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
