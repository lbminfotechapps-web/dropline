import 'project_home_page.dart';

/// Compatibility entry point for the existing project overview route.
class ProjectOverviewPage extends ProjectHomePage {
  const ProjectOverviewPage({
    super.key,
    required super.projectId,
    required super.companyId,
    required super.projectName,
    required super.companyName,
    super.projectType,
    super.onHandovers,
    super.onProjectSetup,
    super.onCheckSheets,
    super.onBack,
  });
}
