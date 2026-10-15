import 'package:dropline/features/event/presentation/add_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Recorder can cancel before native plugin initialisation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AddEventPage()));
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
      await tester.pumpWidget(const MaterialApp(home: AddEventPage()));
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
