import 'location_node.dart';

class SelectedLocation {
  final LocationNode mainArea;
  final LocationNode subArea;
  final LocationNode location;
  final LocationNode specificLocation;

  const SelectedLocation({
    required this.mainArea,
    required this.subArea,
    required this.location,
    required this.specificLocation,
  });

  String get fullPath => [
    mainArea.name,
    subArea.name,
    location.name,
    specificLocation.name,
  ].join(' > ');

  Map<String, dynamic> toJson() {
    return {
      'main_area_id': mainArea.id,
      'main_area_name': mainArea.name,
      'sub_area_id': subArea.id,
      'sub_area_name': subArea.name,
      'location_id': location.id,
      'location_name': location.name,
      'specific_location_id': specificLocation.id,
      'specific_location_name': specificLocation.name,
    };
  }
}