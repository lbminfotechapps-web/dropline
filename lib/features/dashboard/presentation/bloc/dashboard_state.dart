import 'package:dropline/features/dashboard/domain/entity/inpunch_entity.dart';
import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:equatable/equatable.dart';

enum DashboardStatus { initial, loading, success, failure }

class DashboardState extends Equatable {
  final DashboardStatus dashboardStatus;
  final DashboardStatus punchInStatus;
  final String errorMessage;
  final List<ProjectEntity> projectList;

  final InPunchEntity? inPunchData;

  const DashboardState({
    this.dashboardStatus = DashboardStatus.initial,
    this.punchInStatus = DashboardStatus.initial,
    this.errorMessage = '',
    this.projectList = const [],
    this.inPunchData,
  });

  DashboardState copyWith({
    DashboardStatus? dashboardStatus,
    DashboardStatus? punchInStatus,
    String? errorMessage,
    List<ProjectEntity>? projectList,
    InPunchEntity? inPunchData,
  }) {
    return DashboardState(
      dashboardStatus: dashboardStatus ?? this.dashboardStatus,
      punchInStatus: punchInStatus ?? this.punchInStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      projectList: projectList ?? this.projectList,
      inPunchData: inPunchData ?? this.inPunchData,
    );
  }

  @override
  List<Object?> get props => [
    dashboardStatus,
    punchInStatus,
    errorMessage,
    projectList,
    inPunchData,
  ];
}
