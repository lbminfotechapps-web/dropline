import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:dropline/features/dashboard/domain/repository/dashboard_repo.dart';

class DashboardUsecase {
  final DashboardRepo dashboardRepo;

  DashboardUsecase(this.dashboardRepo);

  Future<ProjectResponseEntity> getProjects() async {
    return dashboardRepo.getProjects();
  }
}
