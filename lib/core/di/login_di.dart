import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/auth/data/datasource/login_remote_data_source.dart';
import 'package:dropline/features/auth/data/repositories/login_repository_impl.dart';
import 'package:dropline/features/auth/domain/repositories/login_repository.dart';
import 'package:dropline/features/auth/domain/usecases/login_usecase.dart';
import 'package:dropline/features/auth/presentation/bloc/login_bloc.dart';

void initLoginDi(GetIt sl) {
  sl.registerLazySingleton<LoginRemoteDataSource>(
    () => LoginRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<LoginRepository>(
    () => LoginRepositoryImpl(sl<LoginRemoteDataSource>(), sl<SecureStorage>()),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl<LoginRepository>()));
  sl.registerFactory(() => LoginBloc(sl<LoginUseCase>()));
}
