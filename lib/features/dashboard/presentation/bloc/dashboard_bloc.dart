import 'dart:async';

import 'package:dropline/features/dashboard/domain/usecase/dashboard_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardUsecase dashboardUsecase;

  DashboardBloc(this.dashboardUsecase) : super(const DashboardState()) {
    on<GetProjectList>(_onGetProjectList);
    on<PunchInEvent>(_onPunchIn);
  }

  Future<void> _onGetProjectList(
    GetProjectList event,
    Emitter<DashboardState> emit,
  ) async {
    // STEP 1: Loading
    emit(
      state.copyWith(
        dashboardStatus: DashboardStatus.loading,
        errorMessage: '',
      ),
    );

    try {
      final response = await dashboardUsecase.getProjects();

      if (response.status) {
        emit(
          state.copyWith(
            dashboardStatus: DashboardStatus.success,
            projectList: response.result,
            errorMessage: '',
          ),
        );

        debugPrint('Projects loaded: ${response.result.length}');
      } else {
        emit(
          state.copyWith(
            dashboardStatus: DashboardStatus.failure,
            projectList: [],
            errorMessage: response.message.isNotEmpty
                ? response.message
                : 'Failed to load projects',
          ),
        );
      }
    } catch (e) {
      debugPrint('Dashboard BLoC Error: $e');

      emit(
        state.copyWith(
          dashboardStatus: DashboardStatus.failure,
          projectList: [],
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onPunchIn(
    PunchInEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.punchInStatus == DashboardStatus.loading) return;
    emit(
      state.copyWith(punchInStatus: DashboardStatus.loading, errorMessage: ''),
    );

    try {
      final response = await dashboardUsecase.punchIn(
        event.loginUserId,
        event.projectName,
        event.projectId,
      );

      if (response.status && response.result.isNotEmpty) {
        emit(
          state.copyWith(
            punchInStatus: DashboardStatus.success,
            errorMessage: response.message,
            inPunchData: response.result.first,
          ),
        );

        debugPrint('Punch In Success: ${response.message}');
      } else {
        emit(
          state.copyWith(
            punchInStatus: DashboardStatus.failure,
            errorMessage: response.message.isNotEmpty
                ? response.message
                : 'Punch In failed',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          punchInStatus: DashboardStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
