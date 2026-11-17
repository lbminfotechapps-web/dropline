import 'package:dropline/features/event/data/repositories/event_draft_store.dart';
import 'package:dropline/features/event/presentation/pages/my_updates_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets('records grid filters and opens notes at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      EventDraftRecord record(
        String text,
        EventItemType type,
        DateTime date,
        String project,
      ) => EventDraftRecord(
        date: date,
        projectName: project,
        item: EventDraftItem(
          id: date
              .add(const Duration(hours: 12))
              .microsecondsSinceEpoch
              .toString(),
          type: type,
          name: text,
          text: text,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MyUpdatesPage(
            recordsLoader: () async => [
              record(
                'Check the pipe position',
                EventItemType.note,
                today,
                'Alpha',
              ),
              record('Photo', EventItemType.photo, today, 'Alpha'),
              record('Voice recording', EventItemType.audio, today, 'Beta'),
              record(
                'Skirting boards arrived',
                EventItemType.note,
                DateTime(today.year, today.month, today.day - 1),
                'Beta',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Records'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();
      expect(find.text('Check the pipe position'), findsNothing);
      expect(find.text('Yesterday'), findsNothing);
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check the pipe position'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Yesterday'));
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsNothing);
      expect(find.text('Skirting boards arrived'), findsOneWidget);
      expect(find.text('Filters · 1'), findsOneWidget);
      await tester.tap(find.text('All projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alpha').last);
      await tester.pumpAndSettle();
      expect(find.text('No matching records'), findsOneWidget);
      await tester.ensureVisible(find.text('Clear filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(find.text('Check the pipe position'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
