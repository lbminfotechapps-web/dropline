import 'package:dropline/features/projectevent/presentation/project_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('new categories can be edited and deleted', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ProjectEventPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ New category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Trip hazard\nTrip hazard');
    for (final name in ['Quality', '  QUALITY  ', 'Safety']) {
      await tester.enterText(find.byType(TextFormField).first, name);
      await tester.ensureVisible(find.text('Save category & events'));
      await tester.tap(find.text('Save category & events'));
      await tester.pumpAndSettle();
      expect(find.text('A category with this name already exists'), findsOneWidget);
      expect(find.text('New category'), findsOneWidget);
    }
    await tester.enterText(find.byType(TextFormField).first, 'Custom category');
    await tester.pumpAndSettle();
    expect(find.text('A category with this name already exists'), findsNothing);
    expect(Form.of(tester.element(find.byType(TextFormField).last)).validate(), isTrue);
    await tester.enterText(find.byType(TextFormField).last, '1. ');
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      '1. ',
    );
    await tester.enterText(find.byType(TextFormField).last, '1. First event\n');
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      '1. First event\n2. ',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      '1. First event\n2. Second event\n',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      '1. First event\n2. Second event\n3. ',
    );
    await tester.enterText(find.byType(TextFormField).first, 'Custom category');
    await tester.enterText(
      find.byType(TextFormField).last,
      'First event\nSecond event',
    );
    await tester.ensureVisible(find.text('Save category & events'));
    await tester.tap(find.text('Save category & events'));
    await tester.pumpAndSettle();
    expect(find.text('Custom category'), findsOneWidget);
    await tester.tap(find.text('First event · Second event'));
    await tester.pumpAndSettle();
    expect(find.text('Edit category'), findsOneWidget);
    expect(Form.of(tester.element(find.byType(TextFormField).first)).validate(), isTrue);
    await tester.enterText(find.byType(TextFormField).first, 'safety');
    await tester.pumpAndSettle();
    expect(find.text('A category with this name already exists'), findsOneWidget);
    expect(find.text('1. First event\n2. Second event'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Updated category',
    );
    await tester.enterText(find.byType(TextFormField).last, 'Updated event');
    await tester.ensureVisible(find.text('Save category & events'));
    await tester.tap(find.text('Save category & events'));
    await tester.pumpAndSettle();
    expect(find.text('Custom category'), findsNothing);
    expect(find.text('Updated category'), findsOneWidget);
    expect(find.text('Updated event'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: ProjectEventPage()));
    await tester.pumpAndSettle();
    expect(find.text('Updated category'), findsOneWidget);
    expect(find.text('Updated event'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete Updated category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Updated category'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete Updated category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Updated category'), findsNothing);
    expect(find.text('Quality'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: ProjectEventPage()));
    await tester.pumpAndSettle();
    expect(find.text('Updated category'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getKeys().where(
        (key) => key.startsWith('project_event_categories_v1:'),
      ),
      hasLength(1),
    );
  });
}
