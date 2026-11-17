import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
  final String projectId;
  final String projectName;
  final String projectType;

  String get typeLabel =>
      projectType.trim().toLowerCase() == 'business' ? 'Business' : 'Personal';

  const ProjectEntity({
    required this.projectId,
    required this.projectName,
    this.projectType = 'Personal',
  });

  @override
  List<Object?> get props => [projectId, projectName, projectType];
}

class ProjectResponseEntity extends Equatable {
  final bool status;
  final String message;
  final List<ProjectEntity> result;

  const ProjectResponseEntity({
    required this.status,
    required this.message,
    required this.result,
  });

  @override
  List<Object?> get props => [status, message, result];
}
