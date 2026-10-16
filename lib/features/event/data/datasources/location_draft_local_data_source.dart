
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../event/domain/entities/event_draft_scope.dart';
import '../../domain/entities/location_node.dart';
import '../../domain/entities/selected_location.dart';

class LocationDraftLocalDataSource {
  LocationDraftLocalDataSource({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider =
           directoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directoryProvider;

  // Serialize writes within this data-source instance.
  Future<void> _writes = Future.value();

  Future<Directory> _scopeFolder(
    EventDraftScope scope,
  ) async {
    final root = await _directoryProvider();

    return Directory(
      '${root.path}/event_location_drafts/${scope.folderKey}',
    ).create(recursive: true);
  }

  Future<File> _getFile(
    EventDraftScope scope,
    String name,
  ) async {
    final folder = await _scopeFolder(scope);
    return File('${folder.path}/$name');
  }

  Future<void> _writeJson(
    EventDraftScope scope,
    String name,
    Object data,
  ) {
    final snapshot = jsonEncode(data);

    final operation = _writes.then((_) async {
      final file = await _getFile(scope, name);
      final temp = File('${file.path}.tmp');

      await temp.writeAsString(
        snapshot,
        flush: true,
      );

      // On supported platforms, rename within the
      // same directory replaces the target.
      await temp.rename(file.path);
    });

    _writes = operation.catchError((Object _) {});
    return operation;
  }

  // ==========================================
  // HIERARCHY
  // ==========================================

  Future<List<LocationNode>> loadHierarchy(
    EventDraftScope scope,
  ) async {
    await _writes;

    final file = await _getFile(
      scope,
      'hierarchy.json',
    );

    if (!await file.exists()) {
      return [];
    }

    final decoded = jsonDecode(
      await file.readAsString(),
    );

    if (decoded is! List) {
      throw const FormatException(
        'Invalid hierarchy data',
      );
    }

    return decoded.map((entry) {
      return LocationNode.fromJson(
        Map<String, dynamic>.from(entry as Map),
      );
    }).toList();
  }

  Future<void> saveHierarchy(
    EventDraftScope scope,
    List<LocationNode> nodes,
  ) {
    return _writeJson(
      scope,
      'hierarchy.json',
      nodes.map((node) => node.toJson()).toList(),
    );
  }

  // ==========================================
  // SELECTED LOCATION
  // ==========================================

  Future<SelectedLocation?> loadSelection(
    EventDraftScope scope,
  ) async {
    await _writes;

    final file = await _getFile(
      scope,
      'selection.json',
    );

    if (!await file.exists()) {
      return null;
    }

    final decoded = jsonDecode(
      await file.readAsString(),
    );

    if (decoded is! Map) {
      throw const FormatException(
        'Invalid selected location',
      );
    }

    return SelectedLocation.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<void> saveSelection(
    EventDraftScope scope,
    SelectedLocation selection,
  ) {
    return _writeJson(
      scope,
      'selection.json',
      selection.toJson(),
    );
  }

  Future<void> clearSelection(
    EventDraftScope scope,
  ) async {
    await _writes;

    final file = await _getFile(
      scope,
      'selection.json',
    );

    if (await file.exists()) {
      await file.delete();
    }
  }
}
