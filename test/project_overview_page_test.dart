import 'package:dropline/features/project_setup/presentation/pages/project_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(414, 780)]) {
    testWidgets('project overview layout and actions at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var handovers = 0;
      var setup = 0;
      var back = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectHomePage(
            projectId: 'project-1',
            companyId: 'company-1',
            projectName: 'Laxmi Gauri',
            companyName: 'Apex Build',
            onHandovers: () => handovers++,
            onProjectSetup: () => setup++,
            onBack: () => back++,
          ),
        ),
      );
      expect(find.text('Business · Shared project'), findsOneWidget);
      expect(find.text('Apex Build · Project owner'), findsOneWidget);
      await tester.tap(find.text('See what needs doing'));
      expect(handovers, 1);
      await tester.tap(find.text('Master flow'));
      expect(setup, 1);
      await tester.tap(find.text('My check sheets'));
      await tester.pumpAndSettle();
      expect(find.text('No check sheets assigned'), findsOneWidget);
      expect(find.text('Laxmi Gauri · Apex Build'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back to workspace'));
      expect(back, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
