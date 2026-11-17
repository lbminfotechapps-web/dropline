import 'dart:convert';
import 'dart:io';

import 'package:dropline/features/event/data/repositories/event_draft_store.dart';
import 'package:dropline/features/event/data/services/event_submission_preview_service.dart';
import 'package:dropline/features/event/domain/entities/event_draft_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('submission includes selected attachments and preserves other drafts', () async {
    final root = await Directory.systemTemp.createTemp('attachment_selection_');
    addTearDown(() => root.delete(recursive: true));
    final date = DateTime(2026, 11, 17);
    final key = EventDraftStore.scope(userId: 'u', project: 'Project', date: date, slotId: '1');
    final store = EventDraftStore(directory: () async => root);
    const items = [
      EventDraftItem(id: 'a', type: EventItemType.photo, name: 'Photo', fileName: 'a.jpg'),
      EventDraftItem(id: 'b', type: EventItemType.pdf, name: 'PDF', fileName: 'b.pdf'),
      EventDraftItem(id: 'c', type: EventItemType.audio, name: 'Audio', fileName: 'c.m4a'),
    ];
    await store.save(key, items);
    for (final item in items) {
      await (await store.file(key, item)).writeAsBytes([1, 2, 3]);
    }
    final scope = EventDraftScope(userId: 'u', projectId: 'p', date: date,
      timeSlotId: '1', selectedItemIds: {'a', 'c'});
    final service = EventSubmissionPreviewService(directoryProvider: () async => root);
    final preview = await service.previewOnly(scope: scope, projectName: 'Project');
    expect((preview['items'] as List).map((e) => e['id']), ['a', 'c']);
    expect((await store.load(key)).length, 3);
    final result = await service.previewAndClear(scope: scope, projectName: 'Project');
    expect((result['items'] as List).map((e) => e['id']), ['a', 'c']);
    expect((await store.load(key)).map((e) => e.id), ['b']);
    expect(await (await store.file(key, items[1])).exists(), isTrue);
    expect(jsonEncode(result), contains('local_file_path'));
  });
}
