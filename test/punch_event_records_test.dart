import 'package:dropline/features/event/data/repositories/event_draft_store.dart';
import 'package:dropline/features/punch/presentation/widgets/punch_event_records.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows today, expands older dates and opens notes', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PunchEventRecords(
              records: [
                EventDraftRecord(
                  date: today,
                  item: const EventDraftItem(
                    id: 'today',
                    type: EventItemType.note,
                    name: 'Note',
                    text: 'Wall ready for inspection',
                  ),
                ),
                EventDraftRecord(
                  date: today.subtract(const Duration(days: 1)),
                  item: const EventDraftItem(
                    id: 'old',
                    type: EventItemType.note,
                    name: 'Note',
                    text: 'Previous work',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Wall ready for inspection'), findsOneWidget);
    expect(find.text('Previous work'), findsNothing);
    await tester.tap(find.text('View Old Records'));
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Previous work'), findsOneWidget);
    await tester.tap(find.text('Wall ready for inspection'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
