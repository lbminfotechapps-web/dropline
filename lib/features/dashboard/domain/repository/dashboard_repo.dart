import 'package:dropline/features/dashboard/domain/entity/inpunch_entity.dart';
import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';

abstract class DashboardRepo {
  Future<ProjectResponseEntity> getProjects();

  Future<InPunchResponseEntity> punchIn(
    String loginUserId,
    String projectName,
    String projectId,
    String type,
    String id,
  );
}
