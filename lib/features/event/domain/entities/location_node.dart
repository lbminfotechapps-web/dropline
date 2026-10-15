enum LocationLevel {
  mainArea,
  subArea,
  location,
  specificLocation,
}

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
}