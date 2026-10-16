import 'package:dropline/features/dashboard/domain/entity/inpunch_entity.dart';
import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:dropline/features/dashboard/domain/repository/dashboard_repo.dart';

class DashboardUsecase {
  final DashboardRepo dashboardRepo;

  DashboardUsecase(this.dashboardRepo);

  Future<ProjectResponseEntity> getProjects() async {
    return await dashboardRepo.getProjects();
  }

 Future<InPunchResponseEntity> punchIn(
  String loginUserId,
  String projectName,
  String projectId,
) async {
  return await dashboardRepo.punchIn(
    loginUserId,
    projectName,
    projectId,
  );
}
}
