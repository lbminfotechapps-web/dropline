import 'package:dio/dio.dart';
import 'package:dropline/features/event/data/datasources/time_slot_remote_datasource.dart';
import 'package:dropline/features/event/data/repositories/event_draft_store.dart';
import 'package:dropline/features/event/presentation/pages/add_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Slots extends TimeSlotRemoteDataSource {
  _Slots() : super(Dio());
  @override
  Future<List<TimeSlot>> getTimeSlots() async => const [
    TimeSlot(id: '1', time: '00:00'),
    TimeSlot(id: '2', time: '23:59'),
  ];
}

class _Drafts extends EventDraftStore {
  List<EventDraftItem> items = [];
  @override
  Future<List<EventDraftItem>> load(String scope) async => List.of(items);
  @override
  Future<void> save(String scope, List<EventDraftItem> value) async {
    items = List.of(value);
  }

  @override
  Future<void> cacheSlots(List<TimeSlot> slots) async {}
}

void main() {
  testWidgets('timeline and time slot menu stay in sync', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddEventPage(
          projectId: '1',
          projectName: 'Project',
          draftStore: _Drafts(),
          timeSlotDataSource: _Slots(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final picker = find.byTooltip('Choose time slot');
    final alternate = find.textContaining('· 23:59').evaluate().isEmpty
        ? '23:59'
        : '00:00';
    expect(find.text(alternate), findsOneWidget);

    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(find.text(alternate), findsNWidgets(2));

    await tester.tap(find.text(alternate).last);
    await tester.pumpAndSettle();
    expect(find.text(alternate), findsOneWidget);
    expect(find.textContaining('· $alternate'), findsOneWidget);
  });

  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets('note remains editable above keyboard at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final store = _Drafts();
      await tester.pumpWidget(
        MaterialApp(
          home: AddEventPage(
            projectId: '1',
            projectName: 'Project',
            draftStore: store,
            timeSlotDataSource: _Slots(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Note'));
      await tester.tap(find.text('Note'));
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      final editorState = tester.state(find.byType(EditableText));
      final focus = tester.widget<TextField>(field).focusNode!;
      expect(focus.hasFocus, isTrue);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(EditableText)), same(editorState));
      expect(focus.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(find.text('Done').hitTestable(), findsOneWidget);
      expect(tester.getSize(find.byType(TextField)).height, greaterThan(60));
      expect(
        tester.getBottomRight(find.byType(TextField)).dy,
        lessThanOrEqualTo(size.height - 280),
      );
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'Site visit notes');
      await tester.pumpAndSettle();
      expect(store.items.single.text, 'Site visit notes');
      expect(focus.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.tap(find.text('Done'));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.text('Site visit notes'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
