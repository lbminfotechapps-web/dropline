import 'package:dropline/features/dashboard/domain/entity/inpunch_entity.dart';
import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:dropline/features/dashboard/domain/repository/dashboard_repo.dart';
import 'package:dropline/features/dashboard/domain/usecase/dashboard_usecase.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _DashboardRepo implements DashboardRepo {
  bool failPunchIn = false;

  @override
  Future<ProjectResponseEntity> getProjects() async =>
      const ProjectResponseEntity(
        status: true,
        message: '',
        result: [ProjectEntity(projectId: '1', projectName: 'Project Alpha')],
      );

  @override
  Future<InPunchResponseEntity> punchIn(
    String loginUserId,
    String projectName,
    String projectId,
  ) async {
    if (failPunchIn) throw Exception('Punch request failed');
    return InPunchResponseEntity(
      status: true,
      message: 'Clocked in',
      result: [
        InPunchEntity(
          inpunchId: '10',
          projectId: projectId,
          userId: loginUserId,
          date: '2026-10-16',
          time: '09:00',
          status: '1',
          projectName: projectName,
        ),
      ],
    );
  }
}

void main() {
  for (final fails in [false, true]) {
    test(
      'Punch-in ${fails ? 'failure' : 'success'} preserves loaded projects',
      () async {
        final repo = _DashboardRepo()..failPunchIn = fails;
        final bloc = DashboardBloc(DashboardUsecase(repo));
        addTearDown(bloc.close);
        final projectsLoaded = bloc.stream.firstWhere(
          (state) => state.dashboardStatus == DashboardStatus.success,
        );
        bloc.add(const GetProjectList());
        await projectsLoaded;
        final finished = bloc.stream.firstWhere(
          (state) =>
              state.punchInStatus ==
              (fails ? DashboardStatus.failure : DashboardStatus.success),
        );
        bloc.add(
          const PunchInEvent(
            loginUserId: '2',
            projectName: 'Custom project',
            projectId: '',
          ),
        );
        final state = await finished;
        expect(state.dashboardStatus, DashboardStatus.success);
        expect(state.projectList.single.projectName, 'Project Alpha');
        if (fails) {
          expect(state.errorMessage, 'Punch request failed');
        } else {
          expect(state.inPunchData?.projectName, 'Custom project');
          expect(state.inPunchData?.projectId, '');
        }
      },
    );
  }
}
