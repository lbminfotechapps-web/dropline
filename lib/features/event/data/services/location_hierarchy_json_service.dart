
import 'dart:convert';

import '../../domain/entities/location_node.dart';

class LocationHierarchyJsonService {
  const LocationHierarchyJsonService();

  Map<String, dynamic> buildHierarchy(
    List<LocationNode> nodes,
  ) {
    List<LocationNode> children(
      String? parentId,
      LocationLevel level,
    ) {
      return nodes.where((node) {
        return node.parentId == parentId &&
            node.level == level;
      }).toList();
    }

    final buildings = <String, dynamic>{};

    for (final area in children(
      null,
      LocationLevel.mainArea,
    )) {
      final subAreas = <String, dynamic>{};

      for (final subArea in children(
        area.id,
        LocationLevel.subArea,
      )) {
        final locations = <String, dynamic>{};

        for (final location in children(
          subArea.id,
          LocationLevel.location,
        )) {
          final specificLocations = children(
            location.id,
            LocationLevel.specificLocation,
          ).map((node) => node.name).toList();

          locations[location.name] = specificLocations;
        }

        subAreas[subArea.name] = locations;
      }

      buildings[area.name] = subAreas;
    }

    return {
      'buildings': buildings,
    };
  }

  String toPrettyJson(List<LocationNode> nodes) {
    return const JsonEncoder.withIndent('  ').convert(
      buildHierarchy(nodes),
    );
  }
}
