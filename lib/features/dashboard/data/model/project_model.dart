import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';


class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.projectId,
    required super.projectName,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      projectId: json['fld_project_id']?.toString() ?? '',
      projectName: json['fld_project_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fld_project_id': projectId,
      'fld_project_name': projectName,
    };
  }
}



class ProjectResponseModel extends ProjectResponseEntity {
  const ProjectResponseModel({
    required super.status,
    required super.message,
    required List<ProjectModel> result,
  }) : super(result: result);

  factory ProjectResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProjectResponseModel(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      result: (json['result'] as List<dynamic>? ?? [])
          .map(
            (item) => ProjectModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result.map((item) {
        return {
          'fld_project_id': item.projectId,
          'fld_project_name': item.projectName,
        };
      }).toList(),
    };
  }
}