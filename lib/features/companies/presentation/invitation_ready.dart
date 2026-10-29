import 'package:flutter/material.dart';

class InvitationReadyPage extends StatelessWidget {
  const InvitationReadyPage({
    super.key,
    this.adminName = 'Rahul Sharma',
    this.companyName = 'PlasterCo',
    this.projectName = 'Laxmi Gauri',
    this.onSendInDropline,
    this.onShareWhatsApp,
    this.onShareSms,
  });

  final String adminName;
  final String companyName;
  final String projectName;
  final VoidCallback? onSendInDropline;
  final VoidCallback? onShareWhatsApp;
  final VoidCallback? onShareSms;

  static const _background = Color(0xFF03283B);
  static const _surface = Color(0xFF0B2E44);
  static const _border = Color(0xFF264C63);
  static const _muted = Color(0xFF80B2CD);
  static const _text = Color(0xFFE9F2F8);

  void _pendingIntegration(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation sharing is not connected yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = adminName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
    final firstName = words.isEmpty ? 'your admin' : words.first;
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
            Widget shareAction(
              String title,
              IconData icon,
              VoidCallback? action,
            ) => Padding(
              padding: EdgeInsets.only(bottom: 6 * s),
              child: SizedBox(
                height: 30 * s,
                child: OutlinedButton(
                  onPressed: action ?? () => _pendingIntegration(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10 * s),
                    side: const BorderSide(color: Color(0xFF3D6E8B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4 * s),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 15 * s, color: _muted),
                      SizedBox(width: 11 * s),
                      Expanded(child: label(title, size: 8, bold: true)),
                      Icon(Icons.chevron_right, color: _muted, size: 14 * s),
                    ],
                  ),
                ),
              ),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 6 * s, 10 * s, 20 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 26 * s).clamp(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                label('Invitation ready', size: 12, bold: true),
                                label(projectName, size: 6.5, color: _muted),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10 * s),
                      Container(
                        padding: EdgeInsets.all(8 * s),
                        decoration: BoxDecoration(
                          color: _surface,
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(5 * s),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12 * s,
                              backgroundColor: const Color(0xFF234963),
                              child: label(
                                initials,
                                size: 9,
                                color: _muted,
                                bold: true,
                              ),
                            ),
                            SizedBox(width: 8 * s),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  label(adminName, size: 8, bold: true),
                                  label(
                                    '$companyName · Company admin',
                                    size: 6,
                                    color: _muted,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 4 * s),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4 * s,
                                vertical: 2 * s,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF353D2E),
                                border: Border.all(
                                  color: const Color(0xFF6C7139),
                                ),
                                borderRadius: BorderRadius.circular(4 * s),
                              ),
                              child: label(
                                'Pending',
                                size: 5.5,
                                color: const Color(0xFFD4DA79),
                                bold: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10 * s),
                      label(
                        'Invite $firstName to join your project.',
                        size: 10,
                        bold: true,
                      ),
                      SizedBox(height: 9 * s),
                      shareAction(
                        'Send in Dropline',
                        Icons.send_outlined,
                        onSendInDropline,
                      ),
                      shareAction(
                        'Share on WhatsApp',
                        Icons.chat_outlined,
                        onShareWhatsApp,
                      ),
                      shareAction(
                        'Share by SMS',
                        Icons.sms_outlined,
                        onShareSms,
                      ),
                      SizedBox(height: 4 * s),
                      label(
                        'Not on Dropline? The link helps them install and join.',
                        size: 6.5,
                        color: _muted,
                      ),
                      SizedBox(height: 20 * s),
                      const Spacer(),
                      Divider(color: _border, height: 16 * s),
                      label(
                        'Pending until accepted',
                        size: 6.5,
                        color: _muted,
                        align: TextAlign.center,
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
