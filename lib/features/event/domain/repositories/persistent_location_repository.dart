
import 'package:dropline/features/event/data/datasources/location_draft_local_data_source.dart';

import '../../domain/entities/location_node.dart';
import '../../domain/repositories/location_repository.dart';

import '../../../event/domain/entities/event_draft_scope.dart';

class PersistentLocationRepository implements LocationRepository {
  final LocationDraftLocalDataSource localDataSource;
  final EventDraftScope scope;

  Future<void> _operations = Future.value();

  PersistentLocationRepository({
    required this.localDataSource,
    required this.scope,
  });

  @override
  Future<List<LocationNode>> getChildren({
    required LocationLevel level,
    String? parentId,
  }) async {
    await _operations;

    final nodes = await localDataSource.loadHierarchy(scope);

    return List.unmodifiable(
      nodes.where(
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
  }) {
    final operation = _operations.then((_) async {
      final cleanedName = name.trim();

      if (cleanedName.isEmpty) {
        throw ArgumentError('Please enter a name');
      }

      final nodes = await localDataSource.loadHierarchy(scope);

      if (level == LocationLevel.mainArea) {
        if (parentId != null) {
          throw StateError('Main Area cannot have a parent');
        }
      } else {
        final expectedParentLevel = switch (level) {
          LocationLevel.subArea => LocationLevel.mainArea,
          LocationLevel.location => LocationLevel.subArea,
          LocationLevel.specificLocation => LocationLevel.location,
          LocationLevel.mainArea => LocationLevel.mainArea,
        };

        final hasValidParent = nodes.any(
          (node) =>
              node.id == parentId &&
              node.level == expectedParentLevel,
        );

        if (!hasValidParent) {
          throw StateError('Invalid parent location');
        }
      }

      final duplicate = nodes.any(
        (node) =>
            node.level == level &&
            node.parentId == parentId &&
            node.name.toLowerCase() == cleanedName.toLowerCase(),
      );

      if (duplicate) {
        throw StateError('This name already exists');
      }

      // IDs are unique within this slot hierarchy.
      final usedIds = nodes.map((node) => node.id).toSet();
      var idNumber = 1;

      while (usedIds.contains(idNumber.toString())) {
        idNumber++;
      }

      final node = LocationNode(
        id: idNumber.toString(),
        name: cleanedName,
        level: level,
        parentId: parentId,
      );

      await localDataSource.saveHierarchy(
        scope,
        [...nodes, node],
      );

      return node;
    });

    _operations = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );

    return operation;
  }
}
