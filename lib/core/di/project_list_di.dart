import 'package:dropline/core/api_constant/dio_client.dart';
import 'package:dropline/features/me/data/datasources/project_remote_data_source.dart';
import 'package:dropline/features/me/data/repositories/project_repository_impl.dart';
import 'package:dropline/features/me/domain/repositories/project_repository.dart';
import 'package:dropline/features/me/domain/usecases/get_projects_usecase.dart';
import 'package:dropline/features/me/presentation/bloc/project_bloc.dart';
import 'package:get_it/get_it.dart';

Future<void> initProjectDi(GetIt sl) async {
  // Dio Client
  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(() => DioClient());
  }

  // Data Source
  sl.registerLazySingleton<ProjectRemoteDataSource>(
    () => ProjectRemoteDataSourceImpl(sl<DioClient>()),
  );

  // Repository
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(sl<ProjectRemoteDataSource>()),
  );

  // Use Case
  sl.registerLazySingleton<GetProjectsUseCase>(
    () => GetProjectsUseCase(sl<ProjectRepository>()),
  );

  // BLoC
  sl.registerFactory<ProjectBloc>(() => ProjectBloc(sl<GetProjectsUseCase>()));
}
