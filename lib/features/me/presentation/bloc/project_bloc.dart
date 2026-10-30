import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_projects_usecase.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final GetProjectsUseCase getProjectsUseCase;

  ProjectBloc(this.getProjectsUseCase) : super(ProjectInitial()) {
    on<FetchProjectsEvent>(_onFetchProjects);
  }

  Future<void> _onFetchProjects(
    FetchProjectsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());

    try {
      final projects = await getProjectsUseCase();

      emit(ProjectLoaded(projects));
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }
}
