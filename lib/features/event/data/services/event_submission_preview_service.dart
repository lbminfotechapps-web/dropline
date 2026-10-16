
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/event_draft_scope.dart';

class EventSubmissionPreviewService {
  EventSubmissionPreviewService({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider =
            directoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directoryProvider;

  bool _busy = false;

  // Decode directory names generated using Base64 URL encoding.
  List<dynamic>? _decodeScope(String folderName) {
    try {
      final padded = folderName.padRight(
        ((folderName.length + 3) ~/ 4) * 4,
        '=',
      );

      final decoded = utf8.decode(base64Url.decode(padded));
      final value = jsonDecode(decoded);

      if (value is List && value.length == 6) {
        return value;
      }
    } catch (_) {
      // Ignore unrelated folder names.
    }

    return null;
  }

  bool _matchesSession(
    List<dynamic> values, {
    required String userId,
    required String project,
    required DateTime date,
  }) {
    return values[0].toString() == userId &&
        values[1].toString() == project &&
        values[2].toString() == date.year.toString() &&
        values[3].toString() == date.month.toString() &&
        values[4].toString() == date.day.toString();
  }

  Future<Map<String, dynamic>> _readJsonMap(File file) async {
    final value = jsonDecode(await file.readAsString());

    if (value is! Map) {
      throw FormatException(
        'Expected JSON object: ${file.path}',
      );
    }

    return Map<String, dynamic>.from(value);
  }

  Future<List<dynamic>> _readJsonList(File file) async {
    final value = jsonDecode(await file.readAsString());

    if (value is! List) {
      throw FormatException(
        'Expected JSON list: ${file.path}',
      );
    }

    return value;
  }

  Future<Map<String, dynamic>> previewAndClear({
    required EventDraftScope scope,
    required String projectName,
  }) async {
    if (_busy) {
      throw StateError('Submission is already in progress');
    }

    _busy = true;

    try {
      final root = await _directoryProvider();

      final eventRoot = Directory(
        '${root.path}/event_drafts',
      );

      final locationRoot = Directory(
        '${root.path}/event_location_drafts',
      );

      final Map<String, Directory> eventFolders = {};
      final Map<String, Directory> locationFolders = {};

      // =====================================
      // DISCOVER EXISTING EVENT DRAFTS
      // =====================================

      if (await eventRoot.exists()) {
        await for (final entity
            in eventRoot.list(followLinks: false)) {
          if (entity is! Directory) continue;

          final name =
              entity.uri.pathSegments.where((e) => e.isNotEmpty).last;

          final decoded = _decodeScope(name);

          if (decoded == null) continue;

          if (_matchesSession(
            decoded,
            userId: scope.userId,
            project: projectName,
            date: scope.date,
          )) {
            eventFolders[decoded[5].toString()] = entity;
          }
        }
      }

      // =====================================
      // DISCOVER SAVED AREA HIERARCHIES
      // =====================================

      if (await locationRoot.exists()) {
        await for (final entity
            in locationRoot.list(followLinks: false)) {
          if (entity is! Directory) continue;

          final name =
              entity.uri.pathSegments.where((e) => e.isNotEmpty).last;

          final decoded = _decodeScope(name);

          if (decoded == null) continue;

          if (_matchesSession(
            decoded,
            userId: scope.userId,
            project: scope.projectId,
            date: scope.date,
          )) {
            locationFolders[decoded[5].toString()] = entity;
          }
        }
      }

      // Both kinds of saved data belong to the same session.
      final slotIds = {
        ...eventFolders.keys,
        ...locationFolders.keys,
      }.toList()
        ..sort();

      if (slotIds.isEmpty) {
        throw StateError('No saved event data found');
      }

      final List<Map<String, dynamic>> slots = [];
      final List<Directory> foldersToDelete = [];

      for (final slotId in slotIds) {
        final eventFolder = eventFolders[slotId];
        final locationFolder = locationFolders[slotId];

        final List<dynamic> items = [];
        final List<dynamic> hierarchy = [];
        Map<String, dynamic>? selection;

        // =====================================
        // LOAD NOTES AND ATTACHMENTS
        // =====================================

        if (eventFolder != null) {
          final draftFile = File(
            '${eventFolder.path}/draft.json',
          );

          if (!await draftFile.exists()) {
            throw StateError(
              'Missing draft.json for slot $slotId',
            );
          }

          final savedItems = await _readJsonList(draftFile);

          for (final entry in savedItems) {
            if (entry is! Map) {
              throw FormatException(
                'Invalid draft item in slot $slotId',
              );
            }

            final item = Map<String, dynamic>.from(entry);
            final fileName = item['fileName']?.toString();

            if (fileName != null && fileName.isNotEmpty) {
              // Prevent an unexpected relative file path
              // from pointing outside the draft directory.
              if (fileName.contains('/') ||
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
                  'Attachment missing for slot $slotId: $fileName',
                );
              }

              item['local_file_path'] = attachment.path;
              item['file_size_bytes'] =
                  await attachment.length();
            } else if (item['type'] != 'note') {
              throw StateError(
                'Missing attachment filename in slot $slotId',
              );
            }

            items.add(item);
          }
        }

        // =====================================
        // LOAD AREA HIERARCHY AND SELECTION
        // =====================================

        if (locationFolder != null) {
          final hierarchyFile = File(
            '${locationFolder.path}/hierarchy.json',
          );

          final selectionFile = File(
            '${locationFolder.path}/selection.json',
          );

          if (await hierarchyFile.exists()) {
            hierarchy.addAll(
              await _readJsonList(hierarchyFile),
            );
          }

          if (await selectionFile.exists()) {
            selection = await _readJsonMap(selectionFile);
          }
        }

        // Do not silently delete unfinished time slots.
        if (selection == null) {
          throw StateError(
            'Time slot $slotId has no completed location '
            'selection. Complete this slot before clearing.',
          );
        }

        final hierarchyIds = hierarchy
            .map((node) {
              if (node is! Map) {
                throw const FormatException(
                  'Invalid hierarchy node',
                );
              }
              return node['id']?.toString();
            })
            .toSet();

        // Check that the saved selection refers to nodes
        // inside the same time slot's hierarchy.
        for (final level in [
          'mainArea',
          'subArea',
          'location',
          'specificLocation',
        ]) {
          final node = selection[level];

          if (node is! Map ||
              !hierarchyIds.contains(node['id']?.toString())) {
            throw StateError(
              'Invalid saved $level selection for slot $slotId',
            );
          }
        }

        slots.add({
          'time_slot_id': slotId,
          'items': items,
          'hierarchy': hierarchy,
          'selected_location': selection,
        });

        if (eventFolder != null) {
          foldersToDelete.add(eventFolder);
        }

        if (locationFolder != null) {
          foldersToDelete.add(locationFolder);
        }
      }

      // =====================================
      // CREATE COMPLETE SUBMISSION JSON
      // =====================================

      final payload = <String, dynamic>{
        'user_id': scope.userId,
        'project_id': scope.projectId,
        'project_name': projectName,
        'event_date':
            '${scope.date.year.toString().padLeft(4, '0')}-'
            '${scope.date.month.toString().padLeft(2, '0')}-'
            '${scope.date.day.toString().padLeft(2, '0')}',
        'total_time_slots': slots.length,
        'time_slots': slots,
      };

      // =====================================
      // PRINT COMPLETE PAYLOAD
      // =====================================

      final jsonText =
          const JsonEncoder.withIndent('  ').convert(payload);

      debugPrint('========== EVENT PAYLOAD START ==========');

      // Chunk the output to avoid truncation of long log lines.
      for (var i = 0; i < jsonText.length; i += 800) {
        final end = i + 800 < jsonText.length
            ? i + 800
            : jsonText.length;

        debugPrintSynchronously(
          jsonText.substring(i, end),
        );
      }

      debugPrint('========== EVENT PAYLOAD END ==========');

      // =====================================
      // TEMPORARY DEVELOPMENT-ONLY CLEANUP
      // =====================================
      // No API exists yet, so this is a deliberate
      // local test that simulates submission success.

      for (final folder in foldersToDelete) {
        if (await folder.exists()) {
          await folder.delete(recursive: true);
        }
      }

      debugPrint(
        'EVENT LOCAL CLEANUP COMPLETE: '
        '${foldersToDelete.length} draft folders removed',
      );

      return payload;
    } finally {
      _busy = false;
    }
  }
}
