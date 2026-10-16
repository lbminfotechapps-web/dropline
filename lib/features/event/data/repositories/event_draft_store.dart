import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import '../datasources/time_slot_remote_datasource.dart';

enum EventItemType { note, pdf, photo, audio }

class EventDraftItem {
  const EventDraftItem({
    required this.id,
    required this.type,
    required this.name,
    this.text = '',
    this.fileName,
  });

  final String id;
  final EventItemType type;
  final String name;
  final String text;
  final String? fileName;

  EventDraftItem withText(String value) => EventDraftItem(
    id: id,
    type: type,
    name: name,
    text: value,
    fileName: fileName,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'text': text,
    'fileName': fileName,
  };

  factory EventDraftItem.fromJson(Map<String, dynamic> json) => EventDraftItem(
    id: json['id'] as String,
    type: EventItemType.values.byName(json['type'] as String),
    name: json['name'] as String,
    text: json['text'] as String? ?? '',
    fileName: json['fileName'] as String?,
  );
}

/// Files are copied out of picker caches; paths in metadata stay relative so
/// drafts survive app container path changes as well as app restarts.
class EventDraftStore {
  EventDraftStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directory;
  Future<void> _writes = Future.value();

  Future<File> _rootFile(String name) async {
    final directory = await _directory();
    final folder = await Directory(
      '${directory.path}/event_drafts',
    ).create(recursive: true);
    return File('${folder.path}/$name');
  }

  Future<void> cacheSlots(List<TimeSlot> slots) async {
    final file = await _rootFile('slots.json');
    await file.writeAsString(
      jsonEncode(
        slots.map((slot) => {'id': slot.id, 'time': slot.time}).toList(),
      ),
      flush: true,
    );
  }

  Future<List<TimeSlot>> cachedSlots() async {
    final file = await _rootFile('slots.json');
    if (!await file.exists()) return [];
    return (jsonDecode(await file.readAsString()) as List)
        .map(
          (slot) =>
              TimeSlot(id: slot['id'] as String, time: slot['time'] as String),
        )
        .toList();
  }

  Future<void> rememberCameraScope(String? scope) async {
    final file = await _rootFile('camera.json');
    await file.writeAsString(jsonEncode(scope), flush: true);
  }

  Future<String?> cameraScope() async {
    final file = await _rootFile('camera.json');
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString()) as String?;
  }

  static String scope({
    required String userId,
    required String project,
    required DateTime date,
    required String slotId,
  }) => jsonEncode([userId, project, date.year, date.month, date.day, slotId]);

  Future<Directory> _folder(String scope) async {
    final root = await _directory();
    final key = base64Url.encode(utf8.encode(scope)).replaceAll('=', '');
    return Directory('${root.path}/event_drafts/$key').create(recursive: true);
  }

  Future<List<EventDraftItem>> load(String scope) async {
    await _writes;
    final file = File('${(await _folder(scope)).path}/draft.json');
    if (!await file.exists()) return [];
    final data = jsonDecode(await file.readAsString()) as List;
    return data
        .map(
          (item) =>
              EventDraftItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> save(String scope, List<EventDraftItem> items) {
    final snapshot = jsonEncode(items.map((item) => item.toJson()).toList());
    final operation = _writes.then((_) async {
      final folder = await _folder(scope);
      final temporary = File('${folder.path}/draft.tmp');
      await temporary.writeAsString(snapshot, flush: true);
      await temporary.rename('${folder.path}/draft.json');
    });
    // A failed write is reported to its caller, without blocking later retries.
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  Future<EventDraftItem> importFile(
    String scope,
    XFile source,
    EventItemType type,
  ) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final extension = source.name.contains('.')
        ? source.name.split('.').last.replaceAll(RegExp('[^a-zA-Z0-9]'), '')
        : 'bin';
    final fileName = '$id.$extension';
    await source.saveTo('${(await _folder(scope)).path}/$fileName');
    return EventDraftItem(
      id: id,
      type: type,
      name: source.name,
      fileName: fileName,
    );
  }

  Future<File> file(String scope, EventDraftItem item) async =>
      File('${(await _folder(scope)).path}/${item.fileName}');

  Future<void> replaceFile(
    String scope,
    EventDraftItem item,
    List<int> bytes,
  ) async {
    final target = await file(scope, item);
    final temporary = File('${target.path}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(target.path);
  }
}
