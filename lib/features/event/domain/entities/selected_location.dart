
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

  Map<String, dynamic> toJson() => {
        'mainArea': mainArea.toJson(),
        'subArea': subArea.toJson(),
        'location': location.toJson(),
        'specificLocation': specificLocation.toJson(),
      };

  factory SelectedLocation.fromJson(
    Map<String, dynamic> json,
  ) {
    return SelectedLocation(
      mainArea: LocationNode.fromJson(
        Map<String, dynamic>.from(json['mainArea'] as Map),
      ),
      subArea: LocationNode.fromJson(
        Map<String, dynamic>.from(json['subArea'] as Map),
      ),
      location: LocationNode.fromJson(
        Map<String, dynamic>.from(json['location'] as Map),
      ),
      specificLocation: LocationNode.fromJson(
        Map<String, dynamic>.from(
          json['specificLocation'] as Map,
        ),
      ),
    );
  }
}
