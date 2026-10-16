enum LocationLevel { mainArea, subArea, location, specificLocation }

class LocationNode {
  final String id;
  final String name;
  final LocationLevel level;
  final String? parentId;

  const LocationNode({
    required this.id,
    required this.name,
    required this.level,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level.name,
    'parentId': parentId,
  };

  factory LocationNode.fromJson(Map<String, dynamic> json) {
    return LocationNode(
      id: json['id'].toString(),
      name: json['name'].toString(),
      level: LocationLevel.values.byName(json['level'].toString()),
      parentId: json['parentId']?.toString(),
    );
  }
}
