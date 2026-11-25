import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/features/companies/presentation/start_work.dart';
import 'package:flutter/material.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:dropline/features/projectevent/presentation/project_event.dart';
import 'package:dropline/features/companies/presentation/companies_people.dart';

/// Project configuration menu, styled to match the project setup reference.
class ProjectSetupPage extends StatelessWidget {
  const ProjectSetupPage({
    super.key,
    this.projectId = '',
    this.companyId = '',
    this.projectName = 'Laxmi Gauri',
    this.companyName = 'Apex Build',
    this.onCompaniesAndPeople,
    this.onAreas,
    this.onEvents,
    this.onMasterFlows,
    this.onBackToProject,
  });

  final String projectId;
  final String companyId;
  final String projectName;
  final String companyName;
  final VoidCallback? onCompaniesAndPeople;
  final VoidCallback? onAreas;
  final VoidCallback? onEvents;
  final VoidCallback? onMasterFlows;
  final VoidCallback? onBackToProject;

  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _foreground = Color(0xFFF0F4FC);
  static const _primaryAccent = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    void goBack() {
      if (onBackToProject != null) {
        onBackToProject!();
      } else {
        if (context.canPop()) context.pop();
      }
    }

    return Scaffold(
      backgroundColor: context.backgroundColor(_background),
      appBar: CustomAppBar(
        title: 'Project setup',
        subtitle: '$projectName · $companyName',
        onBackPressed: goBack,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The supplied reference is 262 logical pixels wide.
            final scale = (constraints.maxWidth / 262).clamp(1.0, 1.6);
            Widget menuItem(
              String title,
              String subtitle,
              VoidCallback? onTap, {
              double subtitleFontSize = 8,
            }) {
              return Padding(
                padding: EdgeInsets.only(bottom: 7 * scale),
                child: Material(
                  color: context.surfaceColor(_surface),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9 * scale),
                    side: BorderSide(
                      color: context.borderColor(_border),
                      width: 0.7,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 41 * scale),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * scale,
                          vertical: 7 * scale,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: context.foregroundColor(
                                        _foreground,
                                      ),
                                      fontSize: 10 * scale,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.15 * scale,
                                    ),
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: context.mutedColor(_muted),
                                      fontSize: subtitleFontSize * scale,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8 * scale),
                            Icon(
                              Icons.chevron_right,
                              color: context.mutedColor(_muted),
                              size: 16 * scale,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                12 * scale,
                9 * scale,
                13 * scale,
                12 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          menuItem(
                            'Companies & people',
                            'Company IDs, Admins, teams and permissions',
                            onCompaniesAndPeople ??
                                () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => CompaniesPeoplePage(
                                      projectId: projectId,
                                      companyId: companyId,
                                      projectName: projectName,
                                      companyName: companyName,
                                    ),
                                  ),
                                ),
                            subtitleFontSize: 7,
                          ),
                          menuItem(
                            'Areas',
                            'Set up the places where work happens',
                            onAreas ??
                                () => context.push<Map<String, dynamic>>(
                                  Uri(
                                    path: AppRouter.areas,
                                    queryParameters: {
                                      'projectName': projectName,
                                    },
                                  ).toString(),
                                ),
                          ),
                          menuItem(
                            'Events',
                            'Categories and events for your records',
                            onEvents ??
                                () => Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProjectEventPage(
                                      projectId: projectId,
                                      companyId: companyId,
                                      projectName: projectName,
                                      companyName: companyName,
                                    ),
                                  ),
                                ),
                          ),
                          menuItem(
                            'Set HandOvers',
                            'Activities, references, companies and areas',
                            onMasterFlows ??
                                () {
                                  context.push(
                                    Uri(
                                      path: AppRouter.projectHome,
                                      queryParameters: {
                                        'projectName': projectName,
                                        'projectType': '',
                                        'projectId': projectId,
                                        'companyId': companyId,
                                        'companyName': companyName,
                                      },
                                    ).toString(),
                                  );
                                  // context.push(
                                  //   Uri(
                                  //     path: AppRouter.masterFlow,
                                  //     queryParameters: {
                                  //       'projectId': projectId,
                                  //       'companyId': companyId,
                                  //       'projectName': projectName,
                                  //       'companyName': companyName,
                                  //     },
                                  //   ).toString(),
                                  // );
                                },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * scale),
                  FilledButton(
                    onPressed: goBack,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryAccent,
                      foregroundColor: _background,
                      minimumSize: Size.fromHeight(34 * scale),
                      padding: EdgeInsets.symmetric(vertical: 10 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9 * scale),
                      ),
                      textStyle: TextStyle(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1 * scale,
                      ),
                    ),
                    child: const Text('Back to project'),
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
