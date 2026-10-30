import 'package:dio/dio.dart';
import 'package:dropline/core/api_constant/dio_client.dart';
import 'package:dropline/core/di/dashboard_di.dart';
import 'package:dropline/core/di/login_di.dart';
import 'package:dropline/core/di/project_list_di.dart';
import 'package:dropline/core/di/sub_company_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/event/data/datasources/location_draft_local_data_source.dart';
import 'package:dropline/features/event/data/services/event_submission_preview_service.dart';
import 'package:dropline/features/event/domain/repositories/location_repository_factory.dart';
import 'package:dropline/features/event/domain/repositories/location_selection_repository.dart';
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

  if (!sl.isRegistered<LocationDraftLocalDataSource>()) {
    sl.registerLazySingleton<LocationDraftLocalDataSource>(
      () => LocationDraftLocalDataSource(),
    );
  }

  if (!sl.isRegistered<LocationRepositoryFactory>()) {
    sl.registerLazySingleton<LocationRepositoryFactory>(
      () => LocationRepositoryFactory(sl<LocationDraftLocalDataSource>()),
    );
  }

  if (!sl.isRegistered<LocationSelectionRepository>()) {
    sl.registerLazySingleton<LocationSelectionRepository>(
      () => LocationSelectionRepository(sl<LocationDraftLocalDataSource>()),
    );
  }

  if (!sl.isRegistered<EventSubmissionPreviewService>()) {
    sl.registerLazySingleton<EventSubmissionPreviewService>(
      () => EventSubmissionPreviewService(),
    );
  }
  initLoginDi(sl);
  await initProjectDi(sl);
  await initDashboardDi(sl);
  await initSubCompanyDi(sl);
}
