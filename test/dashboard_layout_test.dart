import 'package:dropline/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:dropline/features/dashboard/presentation/widgets/dashboard_slide_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(412, 1000)]) {
    testWidgets('Dashboard lays out and scrolls at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: DashboardPage()));
      expect(tester.takeException(), isNull);

      final button = find.byType(DashboardSlideButton);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(button).height, 76);
      expect(button.hitTestable(), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
