import '../domain/entities/sub_company_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'invite_company_admin.dart';

class ShareInvitationPage extends StatelessWidget {
  const ShareInvitationPage({
    super.key,
    this.subCompany,
    this.companyName = 'PlasterCo',
    this.adminName = 'Rahul Sharma',
    this.projectName = 'Laxmi Gauri',
    this.ownerCompanyName = 'Apex Build',
    this.companyId = 'DL-C-7K4P2X',
    this.trade = 'Plastering',
    this.onShareInvitation,
  });

  final SubCompanyEntity? subCompany;
  final String companyName;
  final String adminName;
  final String projectName;
  final String ownerCompanyName;
  final String companyId;
  final String trade;
  final VoidCallback? onShareInvitation;

  static const _background = Color(0xFF03283B);
  static const _surface = Color(0xFF062D43);
  static const _border = Color(0xFF16465D);
  static const _muted = Color(0xFF80B2CD);
  static const _text = Color(0xFFE9F2F8);
  static const _lime = Color(0xFFB5FF65);

  Future<void> _copyCompanyId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: companyId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Company ID copied')));
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
              TextAlign? align,
            }) => Text(
              value,
              textAlign: align,
              style: TextStyle(
                color: color,
                fontSize: size * s,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                height: 1.4,
              ),
            );
            BoxDecoration panel() => BoxDecoration(
              color: _surface,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(5 * s),
            );
            Widget emptyState(String title, String subtitle, double height) =>
                Container(
                  constraints: BoxConstraints(minHeight: height * s),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * s,
                    vertical: 10 * s,
                  ),
                  decoration: panel(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, color: _muted, size: 15 * s),
                      SizedBox(height: 3 * s),
                      label(
                        title,
                        size: 7,
                        bold: true,
                        align: TextAlign.center,
                      ),
                      SizedBox(height: 2 * s),
                      label(
                        subtitle,
                        size: 6.5,
                        color: _muted,
                        align: TextAlign.center,
                      ),
                    ],
                  ),
                );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 7 * s, 10 * s, 20 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 22 * s,
                        height: 22 * s,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(companyName),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: _border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5 * s),
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            size: 12 * s,
                            color: _muted,
                          ),
                        ),
                      ),
                      SizedBox(width: 7 * s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            label(companyName, size: 12, bold: true),
                            label(
                              '$projectName · $trade',
                              size: 6.5,
                              color: _muted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 11 * s),
                  Container(
                    padding: EdgeInsets.all(8 * s),
                    decoration: panel(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(
                                'Dropline Company ID',
                                size: 7,
                                color: _muted,
                              ),
                              label(companyId, size: 13, bold: true),
                              SizedBox(height: 2 * s),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyCompanyId(context),
                          tooltip: 'Copy company ID',
                          padding: EdgeInsets.all(3 * s),
                          constraints: BoxConstraints(
                            minWidth: 23 * s,
                            minHeight: 30 * s,
                          ),
                          icon: Icon(
                            Icons.copy_outlined,
                            size: 11 * s,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12 * s),
                  Padding(
                    padding: EdgeInsets.only(left: 2 * s),
                    child: label('Company admins', size: 10, bold: true),
                  ),
                  SizedBox(height: 4 * s),
                  emptyState(
                    'No admin yet',
                    'Invite the company’s representative.',
                    62,
                  ),
                  SizedBox(height: 8 * s),
                  SizedBox(
                    height: 23 * s,
                    child: OutlinedButton(
                      onPressed:
                          onShareInvitation ??
                          () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => InviteCompanyAdminPage(
                                companyId: subCompany?.companyId ?? '',
                                projectId: subCompany?.projectId ?? '',
                                subCompanyId: subCompany?.id ?? '',
                                companyName: companyName,
                                projectName: projectName,
                              ),
                            ),
                          ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(color: Color(0xFF829B3F)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5 * s),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 12 * s, color: _lime),
                          SizedBox(width: 4 * s),
                          label('Invite company admin', size: 7),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * s),
                  Padding(
                    padding: EdgeInsets.only(left: 2 * s),
                    child: label('Team members', size: 10, bold: true),
                  ),
                  SizedBox(height: 4 * s),
                  emptyState(
                    'No team members yet',
                    'The company admin can add their team\nafter joining.',
                    72,
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
