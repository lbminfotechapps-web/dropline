import '../../domain/entities/project_entity.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.projectId,
    required super.projectName,
    required super.companyId,
    required super.projectType,
    required super.companyName,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      projectId: json['fld_project_id']?.toString() ?? '',
      projectName: json['fld_project_name']?.toString() ?? '',
      companyId: json['fld_company_id']?.toString() ?? '',
      projectType: json['fld_project_type']?.toString() ?? '',
      companyName: json['fld_company_name']?.toString() ?? '',
    );
  }
}
