import 'package:flutter/material.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:dropline/features/projectevent/presentation/project_event.dart';
import 'package:dropline/features/companies/presentation/companies_people.dart';

/// Project configuration menu, styled to match the project setup reference.
class ProjectSetupPage extends StatelessWidget {
  const ProjectSetupPage({
    super.key,
    this.projectName = 'Laxmi Gauri',
    this.companyName = 'Apex Build',
    this.onCompaniesAndPeople,
    this.onAreas,
    this.onEvents,
    this.onMasterFlows,
    this.onBackToProject,
  });

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
  static const _lime = Color(0xFFB5FF65);

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
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The supplied reference is 262 logical pixels wide.
            final scale = (constraints.maxWidth / 262).clamp(1.0, 1.6);
            Widget menuItem(
              String title,
              String subtitle,
              VoidCallback? onTap,
            ) {
              return Padding(
                padding: EdgeInsets.only(bottom: 7 * scale),
                child: Material(
                  color: _surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9 * scale),
                    side: const BorderSide(color: _border, width: 0.7),
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
                                      color: _foreground,
                                      fontSize: 10 * scale,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.15 * scale,
                                    ),
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 8 * scale,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8 * scale),
                            Icon(
                              Icons.chevron_right,
                              color: _muted,
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
                  Row(
                    children: [
                      SizedBox(
                        width: 27 * scale,
                        height: 28 * scale,
                        child: OutlinedButton(
                          onPressed: goBack,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: _surface,
                            foregroundColor: _muted,
                            side: const BorderSide(color: _border, width: 0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8 * scale),
                            ),
                          ),
                          child: Semantics(
                            label: 'Back to project',
                            child: Icon(Icons.chevron_left, size: 16 * scale),
                          ),
                        ),
                      ),
                      SizedBox(width: 9 * scale),
                      Expanded(
                        child: Text(
                          'Project setup',
                          style: TextStyle(
                            color: _foreground,
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2 * scale,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
                  Text(
                    '$projectName · $companyName',
                    style: TextStyle(color: _muted, fontSize: 8 * scale),
                  ),
                  SizedBox(height: 14 * scale),
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
                                    builder: (_) => const CompaniesPeoplePage(),
                                  ),
                                ),
                          ),
                          menuItem(
                            'Areas',
                            'Set up the places where work happens',
                            onAreas ??
                                () => context.push<Map<String, dynamic>>(
                                  Uri(
                                    path: AppRouter.areaLabels,
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
                                      projectName: projectName,
                                      companyName: companyName,
                                    ),
                                  ),
                                ),
                          ),
                          menuItem(
                            'Master flows',
                            'Activities, references, companies and areas',
                            onMasterFlows ??
                                () {
                                  context.push('/masterFlow');
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
                      backgroundColor: _lime,
                      foregroundColor: _background,
                      minimumSize: Size.fromHeight(34 * scale),
                      padding: EdgeInsets.symmetric(vertical: 10 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9 * scale),
                      ),
                      textStyle: TextStyle(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w700,
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
