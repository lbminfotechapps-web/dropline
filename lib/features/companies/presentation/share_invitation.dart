import 'package:flutter/material.dart';
import 'project_invitation.dart';

class ShareInvitationPage extends StatelessWidget {
  const ShareInvitationPage({
    super.key,
    this.companyName = 'PlasterCo',
    this.adminName = 'Rahul Sharma',
    this.projectName = 'Laxmi Gauri',
    this.ownerCompanyName = 'Apex Build',
    this.companyId = 'DL-C-7K4P2X',
    this.trade = 'Plastering',
    this.onShareInvitation,
  });

  final String companyName;
  final String adminName;
  final String projectName;
  final String ownerCompanyName;
  final String companyId;
  final String trade;
  final VoidCallback? onShareInvitation;

  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);

  void _openProjectInvitation(BuildContext context) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProjectInvitationPage(
          projectName: projectName,
          companyName: companyName,
          inviterCompany: ownerCompanyName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void backToCompanies() => Navigator.of(context).pop(companyName);

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
            RoundedRectangleBorder shape() => RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7 * s),
            );
            Widget card(String title, String subtitle) => Container(
              padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 6 * s),
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(7 * s),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label(title, size: 8, bold: true),
                  SizedBox(height: 2 * s),
                  label(subtitle, size: 6, color: _muted),
                ],
              ),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 5 * s, 10 * s, 10 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 15 * s).clamp(
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
                              onPressed: backToCompanies,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: _surface,
                                side: const BorderSide(color: _border),
                                shape: shape(),
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
                            child: label(companyName, size: 12, bold: true),
                          ),
                        ],
                      ),
                      SizedBox(height: 10 * s),
                      label(
                        '$projectName · $ownerCompanyName',
                        size: 6.5,
                        color: _muted,
                      ),
                      SizedBox(height: 11 * s),
                      card(companyName, '$companyId · $trade'),
                      SizedBox(height: 5 * s),
                      card(adminName, 'Admin · Invited'),
                      SizedBox(height: 5 * s),
                      SizedBox(
                        height: 28 * s,
                        child: OutlinedButton(
                          onPressed:
                              onShareInvitation ??
                              () => _openProjectInvitation(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: _surface,
                            side: const BorderSide(color: _border),
                            shape: shape(),
                          ),
                          child: label('Share invitation', bold: true),
                        ),
                      ),
                      SizedBox(height: 20 * s),
                      const Spacer(),
                      SizedBox(
                        height: 27 * s,
                        child: FilledButton(
                          onPressed: backToCompanies,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: _lime,
                            foregroundColor: _background,
                            shape: shape(),
                          ),
                          child: label(
                            'Back to companies',
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
