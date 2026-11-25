import 'package:dropline/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'my_check_sheets_page.dart';

/// Project entry screen shown within the Workspace navigation branch.
class ProjectHomePage extends StatelessWidget {
  const ProjectHomePage({
    super.key,
    required this.projectId,
    required this.companyId,
    this.projectName = "ABC",
    required this.companyName,
    this.projectType = 'Business',
    this.onHandovers,
    this.onProjectSetup,
    this.onCheckSheets,
    this.onBack,
  });

  final String projectId;
  final String companyId;
  final String projectName;
  final String companyName;
  final String projectType;
  final VoidCallback? onHandovers;
  final VoidCallback? onProjectSetup;
  final VoidCallback? onCheckSheets;
  final VoidCallback? onBack;

  static const _background = Color(0xFF102633);
  static const _surface = Color(0xFF102734);
  static const _border = Color(0xFF2E4D5E);
  static const _muted = Color(0xFF9FBFD1);
  static const _text = Color(0xFFF0F4FC);

  Map<String, String> get _projectParameters => {
    'projectId': projectId,
    'companyId': companyId,
    'projectName': projectName,
    'companyName': companyName,
  };

  @override
  Widget build(BuildContext context) {
    final type = projectType.trim().toLowerCase() == 'personal'
        ? 'Personal'
        : 'Business';
    return Scaffold(
      backgroundColor: context.backgroundColor(_background),
      appBar: CustomAppBar(
        title: 'Abc',
        subtitle: '$type · Shared project',
        backgroundColor: context.backgroundColor(_background),
        onBackPressed:
            onBack ??
            () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRouter.me);
              }
            },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Divider(height: 1, color: context.borderColor(_border)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '$companyName · Project owner',
                      style: TextStyle(
                        color: context.mutedColor(_muted),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _menuItem(
                      context,
                      icon: Icons.work_outline_rounded,
                      title: 'Master flow',
                      subtitle: 'Master flows',
                      onTap:
                          onProjectSetup ??
                          () => context.push(
                            Uri(
                              path: AppRouter.masterFlow,
                              queryParameters: _projectParameters,
                            ).toString(),
                          ),
                    ),
                             const SizedBox(height: 9),
                    _menuItem(
                      context,
                      icon: Icons.account_tree_outlined,
                      title: 'Handovers',
                      subtitle: 'See what needs doing',
                      onTap:
                          onHandovers ??
                          () => context.push(
                            Uri(
                              path: AppRouter.handovers,
                              queryParameters: _projectParameters,
                            ).toString(),
                          ),
                    ),
             
                    const SizedBox(height: 9),
                    _menuItem(
                      context,
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'My check sheets',
                      subtitle: 'Sheets assigned to your company',
                      onTap:
                          onCheckSheets ??
                          () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MyCheckSheetsPage(
                                projectName: projectName,
                                companyName: companyName,
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) => Material(
    color: context.surfaceColor(_surface),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
      side: BorderSide(color: context.borderColor(_border)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.mutedColor(_muted)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.foregroundColor(_text),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.mutedColor(_muted),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.mutedColor(_muted),
            ),
          ],
        ),
      ),
    ),
  );
}
