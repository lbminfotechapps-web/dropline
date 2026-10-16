import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';

abstract class DashboardRepo {
  Future<ProjectResponseEntity> getProjects();
}
