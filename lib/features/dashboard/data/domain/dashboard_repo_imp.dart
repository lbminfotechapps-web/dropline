import 'package:dropline/features/dashboard/data/datasource/dashboard_datasource.dart';

import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:dropline/features/dashboard/domain/repository/dashboard_repo.dart';

class DashboardRepoImp implements DashboardRepo {
  final DashboardDatasource dashboardDatasource;

  DashboardRepoImp(this.dashboardDatasource);

  @override
  Future<ProjectResponseEntity> getProjects() {
    return dashboardDatasource.getProjects();
  }
}
