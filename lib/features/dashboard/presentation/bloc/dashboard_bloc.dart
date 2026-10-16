import 'dart:async';

import 'package:dropline/features/dashboard/domain/usecase/dashboard_usecase.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardUsecase dashboardUsecase;

  DashboardBloc(this.dashboardUsecase) : super(const DashboardState()) {
    on<GetProjectList>(_ongetProjectList);
  }

  FutureOr<void> _ongetProjectList(
    GetProjectList event,
    Emitter<DashboardState> emit,
  ) {}
}
