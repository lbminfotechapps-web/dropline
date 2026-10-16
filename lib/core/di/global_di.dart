import 'package:dio/dio.dart';
import 'package:dropline/core/api_constant/dio_client.dart';
import 'package:dropline/core/di/dashboard_di.dart';
import 'package:dropline/core/di/login_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initGlobalDi() async {
  sl.registerLazySingleton<Dio>(() => DioClient().client);
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<SecureStorage>(
    () => SecureStorage(sl<FlutterSecureStorage>()),
  );
  initLoginDi(sl);
  await initDashboardDi(sl);
}
