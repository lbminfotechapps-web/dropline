import 'package:flutter/material.dart';
import 'package:dropline/features/project_setup/presentation/pages/project_setup_pages.dart';

class StartWorkPage extends StatelessWidget {
  const StartWorkPage({
    super.key,
    this.projectName = 'Laxmi Gauri',
    this.companyName = 'PlasterCo',
    this.onStartWork,
    this.onHandovers,
    this.onDrawings,
    this.onMyReports,
  });

  final String projectName;
  final String companyName;
  final VoidCallback? onStartWork;
  final VoidCallback? onHandovers;
  final VoidCallback? onDrawings;
  final VoidCallback? onMyReports;

  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);

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
            Widget menuItem(
              String title,
              String subtitle, {
              IconData? icon,
              VoidCallback? onTap,
            }) => Padding(
              padding: EdgeInsets.only(bottom: 5 * s),
              child: Material(
                color: _surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7 * s),
                  side: const BorderSide(color: _border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7 * s,
                      vertical: 6 * s,
                    ),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: _muted, size: 13 * s),
                          SizedBox(width: 5 * s),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(title, size: 8, bold: true),
                              SizedBox(height: 2 * s),
                              label(subtitle, size: 6, color: _muted),
                            ],
                          ),
                        ),
                        SizedBox(width: 5 * s),
                        Icon(Icons.chevron_right, color: _muted, size: 13 * s),
                      ],
                    ),
                  ),
                ),
              ),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 10 * s, 10 * s, 7 * s),
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
                            child: label(projectName, size: 12, bold: true),
                          ),
                        ],
                      ),
                      SizedBox(height: 10 * s),
                      label(
                        'Business · $companyName · Admin',
                        size: 6.5,
                        color: _muted,
                      ),
                      SizedBox(height: 11 * s),
                      menuItem(
                        'Handovers',
                        'Areas, companies and progress',
                        icon: Icons.account_tree_outlined,
                        onTap: onHandovers,
                      ),
                      menuItem(
                        'Drawings',
                        'Open project drawings',
                        icon: Icons.description_outlined,
                        onTap: onDrawings,
                      ),
                      menuItem(
                        'My reports',
                        'Project photos, notes and audio',
                        icon: Icons.article_outlined,
                        onTap: onMyReports,
                      ),
                      menuItem(
                        'Project setup',
                        'Companies & people · Your team',
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => ProjectSetupPage(
                              projectName: projectName,
                              companyName: companyName,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20 * s),
                      const Spacer(),
                      SizedBox(
                        height: 27 * s,
                        child: FilledButton(
                          onPressed: onStartWork,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: _lime,
                            foregroundColor: _background,
                            disabledBackgroundColor: _lime,
                            disabledForegroundColor: _background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7 * s),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.access_time, size: 11 * s),
                              SizedBox(width: 4 * s),
                              label(
                                'Start work',
                                color: _background,
                                bold: true,
                              ),
                            ],
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
