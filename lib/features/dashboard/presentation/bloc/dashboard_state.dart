import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';

enum DashboardStatus { initial, loading, success, failure }

class DashboardState {
  final DashboardStatus dashboardStatus;
  final String? errorMessage;
  final ProjectEntity? projectlist;

  const DashboardState({
    this.dashboardStatus = DashboardStatus.initial,
    this.errorMessage,
    this.projectlist,
  });

  DashboardState copyWith({
    DashboardStatus? dashboardStatus,
    ProjectEntity? projectlist,
    String? errorMessage,
  }) {
    return DashboardState(
      dashboardStatus: dashboardStatus ?? this.dashboardStatus,
      projectlist: projectlist ?? this.projectlist,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
