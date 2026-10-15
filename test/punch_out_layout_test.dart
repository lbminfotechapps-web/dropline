import 'package:dropline/features/punch/presentation/pages/punch_out.dart';
import 'package:dropline/features/punch/presentation/widgets/punch_out_slide_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(369.5, 800), const Size(360, 640)]) {
    testWidgets('Punch out fits and clock out works at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: PunchOutPage()));
      expect(tester.takeException(), isNull);
      expect(find.text('TRIBECA'), findsOneWidget);
      expect(find.text('09:41'), findsOneWidget);
      expect(find.text('02:00'), findsOneWidget);
      await tester.tap(find.text('ADD WORK DETAILS'));
      await tester.pump();
      expect(find.text('Add Work Details clicked'), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.byType(PunchOutPage)),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(PunchOutSlideBar));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byIcon(Icons.keyboard_double_arrow_right_rounded),
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Clock Out action triggered'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
