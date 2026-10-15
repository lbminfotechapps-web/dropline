import '../entities/location_node.dart';

abstract class LocationRepository {
  Future<List<LocationNode>> getChildren({
    required LocationLevel level,
    String? parentId,
  });

  Future<LocationNode> addNode({
    required String name,
    required LocationLevel level,
    String? parentId,
  });
}