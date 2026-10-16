
import '../../../event/domain/entities/event_draft_scope.dart';
import 'location_node.dart';

class LocationFlowArgs {
  final EventDraftScope scope;
  final String projectName;

  final LocationNode? mainArea;
  final LocationNode? subArea;
  final LocationNode? location;

  const LocationFlowArgs({
    required this.scope,
    required this.projectName,
    this.mainArea,
    this.subArea,
    this.location,
  });

  LocationFlowArgs copyWith({
    LocationNode? mainArea,
    LocationNode? subArea,
    LocationNode? location,
    bool clearSubArea = false,
    bool clearLocation = false,
  }) {
    return LocationFlowArgs(
      scope: scope,
      projectName: projectName,
      mainArea: mainArea ?? this.mainArea,
      subArea: clearSubArea
          ? null
          : subArea ?? this.subArea,
      location: clearLocation
          ? null
          : location ?? this.location,
    );
  }
}