import 'package:dropline/features/dashboard/data/datasource/dashboard_datasource.dart';
import 'package:dropline/features/dashboard/domain/entity/inpunch_entity.dart';

import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:dropline/features/dashboard/domain/repository/dashboard_repo.dart';

class DashboardRepoImp implements DashboardRepo {
  final DashboardDatasource dashboardDatasource;

  DashboardRepoImp(this.dashboardDatasource);

  @override
  Future<ProjectResponseEntity> getProjects() async {
    return await dashboardDatasource.getProjects();
  }

 @override
Future<InPunchResponseEntity> punchIn(
  String loginUserId,
  String projectName,
  String projectId,
) async {
  return await dashboardDatasource.punchIn(
    loginUserId,
    projectName,
    projectId,
  );
}
}
