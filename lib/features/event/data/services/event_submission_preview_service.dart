
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/event_draft_scope.dart';

class EventSubmissionPreviewService {
  EventSubmissionPreviewService({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider =
            directoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directoryProvider;

  bool _busy = false;

  String _encodeFolder(String value) {
    return base64Url
        .encode(utf8.encode(value))
        .replaceAll('=', '');
  }

  Future<List<dynamic>> _readJsonList(File file) async {
    final decoded = jsonDecode(await file.readAsString());

    if (decoded is! List) {
      throw FormatException(
        'Invalid JSON list: ${file.path}',
      );
    }

    return decoded;
  }

  // =============================================
  // CONVERT FLAT HIERARCHY TO NESTED JSON
  // =============================================


List<Map<String, dynamic>> buildNestedHierarchy(
  List<dynamic> hierarchy,
) {
  final nodes = hierarchy.map((item) {
    return Map<String, dynamic>.from(item as Map);
  }).toList();

  // =========================================
  // FIND CHILDREN BY PARENT ID AND LEVEL
  // =========================================

  List<Map<String, dynamic>> getChildren(
    String? parentId,
    String level,
  ) {
    return nodes.where((node) {
      return node['parentId']?.toString() == parentId &&
          node['level']?.toString() == level;
    }).toList();
  }

  // =========================================
  // BUILD AREAS
  // =========================================

  final List<Map<String, dynamic>> areas = [];

  final mainAreas = getChildren(
    null,
    'mainArea',
  );

  for (final mainArea in mainAreas) {
    final List<Map<String, dynamic>> subAreas = [];

    final subAreaNodes = getChildren(
      mainArea['id'].toString(),
      'subArea',
    );

    for (final subArea in subAreaNodes) {
      final List<Map<String, dynamic>> locations = [];

      final locationNodes = getChildren(
        subArea['id'].toString(),
        'location',
      );

      for (final location in locationNodes) {
        final specificLocationNodes = getChildren(
          location['id'].toString(),
          'specificLocation',
        );

        final specificLocations = specificLocationNodes
            .map((node) => node['name'].toString())
            .toList();

        locations.add({
          'location_name': location['name'].toString(),
          'specific_locations': specificLocations,
        });
      }

      subAreas.add({
        'sub_area_name': subArea['name'].toString(),
        'locations': locations,
      });
    }

    areas.add({
      'area_name': mainArea['name'].toString(),
      'sub_areas': subAreas,
    });
  }

  return areas;
}


  // =============================================
  // PREVIEW ONLY - NO DELETE
  // =============================================

  Future<Map<String, dynamic>> previewOnly({
    required EventDraftScope scope,
    required String projectName,
  }) async {
    if (_busy) {
      throw StateError(
        'Event preview is already in progress',
      );
    }

    _busy = true;

    try {
      final root = await _directoryProvider();

      // Existing EventDraftStore uses projectName.
      final eventStorageKey = jsonEncode([
        scope.userId,
        projectName,
        scope.date.year,
        scope.date.month,
        scope.date.day,
        scope.timeSlotId,
      ]);

      final eventFolder = Directory(
        '${root.path}/event_drafts/'
        '${_encodeFolder(eventStorageKey)}',
      );

      // LocationDraftLocalDataSource uses projectId.
      final locationFolder = Directory(
        '${root.path}/event_location_drafts/'
        '${scope.folderKey}',
      );

      // ==========================================
      // LOAD NOTES / PDF / PHOTO / AUDIO
      // ==========================================

      final draftFile = File(
        '${eventFolder.path}/draft.json',
      );

      final items = <Map<String, dynamic>>[];

      if (await draftFile.exists()) {
        final savedItems = await _readJsonList(draftFile);

        for (final entry in savedItems) {
          if (entry is! Map) {
            throw const FormatException(
              'Invalid event draft item',
            );
          }

          final item = Map<String, dynamic>.from(entry);

          final type = item['type']?.toString() ?? '';
          final fileName =
              item['fileName']?.toString().trim() ?? '';

          if (type != 'note') {
            if (fileName.isEmpty ||
                fileName.contains('/') ||
                fileName.contains('\\') ||
                fileName == '.' ||
                fileName == '..') {
              throw StateError(
                'Invalid attachment filename: $fileName',
              );
            }

            final attachment = File(
              '${eventFolder.path}/$fileName',
            );

            if (!await attachment.exists()) {
              throw StateError(
                'Attachment not found: $fileName',
              );
            }

            item['local_file_path'] = attachment.path;
            item['file_size_bytes'] =
                await attachment.length();
          }

          items.add(item);
        }
      } else if (await eventFolder.exists()) {
        throw StateError(
          'Missing draft.json for time slot '
          '${scope.timeSlotId}',
        );
      }

      // ==========================================
      // LOAD SAVED HIERARCHY
      // ==========================================

      final hierarchyFile = File(
        '${locationFolder.path}/hierarchy.json',
      );

      final List<dynamic> hierarchy =
          await hierarchyFile.exists()
              ? await _readJsonList(hierarchyFile)
              : [];

      // ==========================================
      // CONVERT HIERARCHY
      // ==========================================

      final areas = buildNestedHierarchy(hierarchy);

      // ==========================================
      // PREPARE FINAL JSON
      // ==========================================

      final eventDate =
          '${scope.date.year.toString().padLeft(4, '0')}-'
          '${scope.date.month.toString().padLeft(2, '0')}-'
          '${scope.date.day.toString().padLeft(2, '0')}';

      final payload = <String, dynamic>{
        'user_id': scope.userId,
        'project_id': scope.projectId,
        'project_name': projectName,
        'event_date': eventDate,
        'time_slot_id': scope.timeSlotId,
        'items': items,
        'areas': areas,
      };

      // No selected_location field.
      // No file deletion.
      // No hierarchy deletion.

      return payload;
    } finally {
      _busy = false;
    }
  }


  
Future<Map<String, dynamic>> previewAndClear({
  required EventDraftScope scope,
  required String projectName,
}) async {
  // STEP 1: Prepare the same JSON used by Finish Setup.
  final payload = await previewOnly(
    scope: scope,
    projectName: projectName,
  );

  // STEP 2: Print the complete JSON before deleting.
  final jsonString =
      const JsonEncoder.withIndent('  ').convert(payload);

  debugPrintSynchronously(
    '========== USE LOCATION JSON START ==========',
  );

  for (var i = 0; i < jsonString.length; i += 800) {
    final end = i + 800 < jsonString.length
        ? i + 800
        : jsonString.length;

    debugPrintSynchronously(
      jsonString.substring(i, end),
    );
  }

  debugPrintSynchronously(
    '========== USE LOCATION JSON END ==========',
  );

  // STEP 3: Resolve only the selected time slot's folders.
  final root = await _directoryProvider();

  final eventStorageKey = jsonEncode([
    scope.userId,
    projectName,
    scope.date.year,
    scope.date.month,
    scope.date.day,
    scope.timeSlotId,
  ]);

  final eventFolder = Directory(
    '${root.path}/event_drafts/'
    '${_encodeFolder(eventStorageKey)}',
  );

  final locationFolder = Directory(
    '${root.path}/event_location_drafts/'
    '${scope.folderKey}',
  );

  // STEP 4: Delete only this time slot's persisted data.
  if (await eventFolder.exists()) {
    await eventFolder.delete(recursive: true);
  }

  if (await locationFolder.exists()) {
    await locationFolder.delete(recursive: true);
  }

  debugPrint(
    'TIME SLOT ${scope.timeSlotId} PRINTED AND CLEARED',
  );

  return payload;
}

}
