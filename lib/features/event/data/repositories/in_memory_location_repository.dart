import '../../domain/entities/location_node.dart';
import '../../domain/repositories/location_repository.dart';

class InMemoryLocationRepository
    implements LocationRepository {
  final List<LocationNode> _nodes = [];

  int _nextId = 1;

  @override
  Future<List<LocationNode>> getChildren({
    required LocationLevel level,
    String? parentId,
  }) async {
    return List.unmodifiable(
      _nodes.where(
        (node) =>
            node.level == level &&
            node.parentId == parentId,
      ),
    );
  }

  @override
  Future<LocationNode> addNode({
    required String name,
    required LocationLevel level,
    String? parentId,
  }) async {
    final cleanedName = name.trim();

    if (cleanedName.isEmpty) {
      throw ArgumentError('Please enter an area name');
    }

    final duplicate = _nodes.any(
      (node) =>
          node.level == level &&
          node.parentId == parentId &&
          node.name.toLowerCase() ==
              cleanedName.toLowerCase(),
    );

    if (duplicate) {
      throw StateError('This name already exists');
    }

    final node = LocationNode(
      id: (_nextId++).toString(),
      name: cleanedName,
      level: level,
      parentId: parentId,
    );

    _nodes.add(node);

    return node;
  }
}