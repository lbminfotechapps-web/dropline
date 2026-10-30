import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
  final String projectId;
  final String projectName;
  final String companyId;
  final String projectType;
  final String companyName;

  const ProjectEntity({
    required this.projectId,
    required this.projectName,
    required this.companyId,
    required this.projectType,
    required this.companyName,
  });

  @override
  List<Object?> get props => [
    projectId,
    projectName,
    companyId,
    projectType,
    companyName,
  ];
}
