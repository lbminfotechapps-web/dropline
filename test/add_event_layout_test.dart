import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dropline/features/event/data/datasources/time_slot_remote_datasource.dart';
import 'package:dropline/features/event/data/repositories/event_draft_store.dart';
import 'package:dropline/features/event/presentation/pages/add_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTimeSlots extends TimeSlotRemoteDataSource {
  FakeTimeSlots() : super(Dio());

  @override
  Future<List<TimeSlot>> getTimeSlots() async => const [
    TimeSlot(id: '2', time: '00:15'),
    TimeSlot(id: '3', time: '00:30'),
  ];
}

class MemoryDraftStore extends EventDraftStore {
  final drafts = <String, List<EventDraftItem>>{};
  bool failSave = false;

  @override
  Future<List<EventDraftItem>> load(String scope) async =>
      List.of(drafts[scope] ?? []);

  @override
  Future<void> save(String scope, List<EventDraftItem> items) async {
    if (failSave) throw const FileSystemException('Storage unavailable');
    drafts[scope] = List.of(items);
  }

  @override
  Future<void> cacheSlots(List<TimeSlot> slots) async {}

  @override
  Future<List<TimeSlot>> cachedSlots() async => const [
    TimeSlot(id: '2', time: '00:15'),
    TimeSlot(id: '3', time: '00:30'),
  ];
}

class OfflineTimeSlots extends FakeTimeSlots {
  @override
  Future<List<TimeSlot>> getTimeSlots() async => throw Exception('Offline');
}

Widget eventApp({EventDraftStore? store}) => MaterialApp(
  home: AddEventPage(
    timeSlotDataSource: FakeTimeSlots(),
    draftStore: store ?? MemoryDraftStore(),
  ),
);

void main() {
  testWidgets('Save failure keeps note available for retry', (tester) async {
    final store = MemoryDraftStore()..failSave = true;
    await tester.pumpWidget(eventApp(store: store));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Keep my note');
    await tester.pumpAndSettle();
    expect(find.text('Save failed. Retry'), findsOneWidget);
    store.failSave = false;
    await tester.ensureVisible(find.text('Save failed. Retry'));
    await tester.tap(find.text('Save failed. Retry'));
    await tester.pumpAndSettle();
    expect(store.drafts.values.single.single.text, 'Keep my note');
    expect(find.text('Save failed. Retry'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Cached slots load when API is unavailable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddEventPage(
          timeSlotDataSource: OfflineTimeSlots(),
          draftStore: MemoryDraftStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('00:15'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Unable to load time slots. Retry'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Multiple notes reload in their own time slot after reopening', (
    tester,
  ) async {
    final store = MemoryDraftStore();
    await tester.pumpWidget(eventApp(store: store));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'First saved note');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Write note'));
    await tester.tap(find.byTooltip('Write note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Second saved note');
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final selected = now.hour * 60 + now.minute >= 30 ? '00:30' : '00:15';
    final other = selected == '00:30' ? '00:15' : '00:30';
    await tester.ensureVisible(find.text(other));
    await tester.tap(find.text(other));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(eventApp(store: store));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'First saved note',
    );
    await tester.ensureVisible(find.text('Note 2'));
    await tester.tap(find.text('Note 2'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Second saved note',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('API time slot selection updates note time', (tester) async {
    await tester.pumpWidget(eventApp());
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final selected = now.hour * 60 + now.minute >= 30 ? '00:30' : '00:15';
    final other = selected == '00:30' ? '00:15' : '00:30';
    expect(find.text(selected), findsNWidgets(2));
    await tester.ensureVisible(find.text(other));
    await tester.tap(find.text(other));
    await tester.pump();
    expect(find.text(other), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Recorder can cancel before native plugin initialisation', (
    tester,
  ) async {
    await tester.pumpWidget(eventApp());
    await tester.pumpAndSettle();
    final mic = find.byTooltip('Record voice note').first;
    await tester.ensureVisible(mic);
    await tester.tap(mic);
    await tester.pumpAndSettle();
    expect(find.text('Voice note'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Voice note'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets('Event composer adapts at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(eventApp());
      await tester.pumpAndSettle();
      expect(find.text('TRIBECA'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'Site visit notes');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Event'));
      await tester.pumpAndSettle();
      expect(find.text('Event').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
