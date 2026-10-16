import 'package:equatable/equatable.dart';



class ProjectEntity extends Equatable {
  final String projectId;
  final String projectName;

  const ProjectEntity({
    required this.projectId,
    required this.projectName,
  });

  @override
  List<Object?> get props => [
        projectId,
        projectName,
      ];
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
  List<Object?> get props => [
        status,
        message,
        result,
      ];
}