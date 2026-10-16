import 'package:dropline/features/event/data/datasources/location_draft_local_data_source.dart';

import '../../../event/domain/entities/event_draft_scope.dart';
import '../../domain/entities/selected_location.dart';


class LocationSelectionRepository {
  final LocationDraftLocalDataSource dataSource;

  const LocationSelectionRepository(this.dataSource);

  Future<SelectedLocation?> getSelection(
    EventDraftScope scope,
  ) {
    return dataSource.loadSelection(scope);
  }

  Future<void> saveSelection(
    EventDraftScope scope,
    SelectedLocation selection,
  ) {
    return dataSource.saveSelection(
      scope,
      selection,
    );
  }

  Future<void> clearSelection(
    EventDraftScope scope,
  ) {
    return dataSource.clearSelection(scope);
  }
}