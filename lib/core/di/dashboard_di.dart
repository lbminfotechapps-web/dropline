import 'package:dropline/core/api_constant/dio_client.dart';
import 'package:dropline/features/dashboard/data/datasource/dashboard_datasource.dart';
import 'package:dropline/features/dashboard/data/domain/dashboard_repo_imp.dart';
import 'package:dropline/features/dashboard/domain/repository/dashboard_repo.dart';
import 'package:dropline/features/dashboard/domain/usecase/dashboard_usecase.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:get_it/get_it.dart';



Future<void> initDashboardDi(GetIt sl) async {
  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(() => DioClient());
  }

  sl.registerLazySingleton<DashboardDatasource>(
    () => DashboardDatasource(sl<DioClient>()),
  );

  sl.registerLazySingleton<DashboardRepo>(
    () => DashboardRepoImp(sl<DashboardDatasource>()),
  );

  sl.registerLazySingleton<DashboardUsecase>(
    () => DashboardUsecase(sl<DashboardRepo>()),
  );

  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(sl<DashboardUsecase>()),
  );
}
