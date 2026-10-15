import 'package:dropline/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:dropline/features/dashboard/data/datasource/project_search_cache.dart';
import 'package:dropline/features/dashboard/presentation/widgets/dashboard_slide_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Adds one project, collapses search, and allows removal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ProjectSearchCache.instance.clearHistory();
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));
    await tester.tap(find.text('SELECT PROJECT'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Project Alpha  ');
    await tester.ensureVisible(find.byTooltip('Add project'));
    await tester.tap(find.byTooltip('Add project'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(InputChip, 'Project Alpha'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.ensureVisible(find.text('SELECT PROJECT'));
    await tester.tap(find.text('SELECT PROJECT'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(InputChip), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Remove project'));
    await tester.tap(find.byTooltip('Remove project'));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNothing);
    await tester.tap(find.text('SELECT PROJECT'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Project Alpha'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'Project Beta');
    await tester.ensureVisible(find.byTooltip('Add project'));
    await tester.tap(find.byTooltip('Add project'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Project Beta'), findsOneWidget);
    expect(find.byType(InputChip), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    ProjectSearchCache.instance.clearHistory();
  });
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
      expect(
        tester.getSize(button).height,
        closeTo(98 * size.width / 591, 0.01),
      );
      expect(button.hitTestable(), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
