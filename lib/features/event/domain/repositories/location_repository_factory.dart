import 'dart:convert';

import 'package:dropline/features/event/data/datasources/location_draft_local_data_source.dart';

import '../../../event/domain/entities/event_draft_scope.dart';
import '../../domain/repositories/location_repository.dart';

import 'persistent_location_repository.dart';

class LocationRepositoryFactory {
  final LocationDraftLocalDataSource dataSource;

  LocationRepositoryFactory(this.dataSource);

  final Map<String, LocationRepository> _repositories = {};

  LocationRepository forScope(EventDraftScope scope) {
    return _repositories.putIfAbsent(
      scope.storageKey,
      () => PersistentLocationRepository(
        localDataSource: dataSource,
        scope: scope,
      ),
    );
  }


  void evictSession(EventDraftScope scope) {
  _repositories.removeWhere((key, value) {
    try {
      final decoded = jsonDecode(key);

      if (decoded is! List || decoded.length != 6) {
        return false;
      }

      return decoded[0].toString() == scope.userId &&
          decoded[1].toString() == scope.projectId &&
          decoded[2] == scope.date.year &&
          decoded[3] == scope.date.month &&
          decoded[4] == scope.date.day;
    } catch (_) {
      return false;
    }
  });
}
}