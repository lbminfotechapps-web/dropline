import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class GetProjectList extends DashboardEvent {
  const GetProjectList();
}

class PunchInEvent extends DashboardEvent {
  final String loginUserId;
  final String projectName;
  final String projectId;

  const PunchInEvent({
    required this.loginUserId,
    required this.projectName,
    required this.projectId,
  });

  @override
  List<Object?> get props => [loginUserId, projectName, projectId];
}
