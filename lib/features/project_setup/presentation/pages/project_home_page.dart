import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dropline/core/router/app_router.dart';
import 'my_check_sheets_page.dart';

/// Project entry screen shown within the Workspace navigation branch.
class ProjectHomePage extends StatelessWidget {
  const ProjectHomePage({
    super.key,
    required this.projectId,
    required this.companyId,
    required this.projectName,
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
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 20, 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton.outlined(
                      tooltip: 'Back to workspace',
                      onPressed:
                          onBack ??
                          () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRouter.me);
                            }
                          },
                      style: IconButton.styleFrom(
                        foregroundColor: _muted,
                        backgroundColor: const Color(0xFF153142),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectName,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$type · Shared project',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '$companyName · Project owner',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _menuItem(
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

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) => Material(
    color: _surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
      side: const BorderSide(color: _border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _muted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _muted),
          ],
        ),
      ),
    ),
  );
}
