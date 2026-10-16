import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:dropline/features/event/data/repositories/event_draft_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late EventDraftStore store;
  String scope(
    String slot, {
    int day = 16,
    String user = '1',
    String project = 'TRIBECA',
  }) => EventDraftStore.scope(
    userId: user,
    project: project,
    date: DateTime(2026, 10, day),
    slotId: slot,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('event-draft-test');
    store = EventDraftStore(directory: () async => directory);
  });
  tearDown(() async => directory.delete(recursive: true));

  test(
    'Multiple items survive new store instance and cache source removal',
    () async {
      final source = File('${directory.path}/picked.pdf');
      await source.writeAsBytes([1, 2, 3]);
      final pdf = await store.importFile(
        scope('2'),
        XFile(source.path),
        EventItemType.pdf,
      );
      final photo = await store.importFile(
        scope('2'),
        XFile(source.path),
        EventItemType.photo,
      );
      final audio = await store.importFile(
        scope('2'),
        XFile(source.path),
        EventItemType.audio,
      );
      const note = EventDraftItem(
        id: 'note-1',
        type: EventItemType.note,
        name: 'Note 1',
        text: 'Saved note',
      );
      await store.save(scope('2'), [note, pdf, photo, audio]);
      await source.delete();
      final reopened = EventDraftStore(directory: () async => directory);
      final items = await reopened.load(scope('2'));
      expect(items.length, 4);
      expect(items.first.text, 'Saved note');
      for (final item in items.skip(1)) {
        expect(await (await reopened.file(scope('2'), item)).readAsBytes(), [
          1,
          2,
          3,
        ]);
      }
      await reopened.replaceFile(scope('2'), pdf, [4, 5]);
      expect(await (await store.file(scope('2'), pdf)).readAsBytes(), [4, 5]);
    },
  );

  test('Drafts stay isolated by slot, date, user and project', () async {
    const note = EventDraftItem(
      id: '1',
      type: EventItemType.note,
      name: 'Note',
      text: 'Private',
    );
    await store.save(scope('2'), [note]);
    for (final other in [
      scope('3'),
      scope('2', day: 17),
      scope('2', user: '2'),
      scope('2', project: 'OTHER'),
    ]) {
      expect(await store.load(other), isEmpty);
    }
  });

  test('Rapid autosaves preserve the most recent text', () async {
    final writes = <Future<void>>[];
    for (var i = 0; i < 20; i++) {
      writes.add(
        store.save(scope('2'), [
          EventDraftItem(
            id: '1',
            type: EventItemType.note,
            name: 'Note',
            text: '$i',
          ),
        ]),
      );
    }
    await Future.wait(writes);
    expect((await store.load(scope('2'))).single.text, '19');
  });
}
