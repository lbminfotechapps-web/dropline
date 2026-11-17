import 'package:dropline/features/masterFlow/data/master_flow_store.dart';
import 'package:dropline/features/masterFlow/presentation/pages/master_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(414, 775)]) {
    testWidgets('new master flow reorders activities and saves at $size', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateMasterFlowScreen(
                        projectId: '1',
                        companyId: '2',
                        projectName: 'Laxmi Gauri',
                        companyName: 'Apex Build',
                        tradeCompanies: ['PlasterCo', 'PaintCo'],
                      ),
                    ),
                  );
                },
                child: const Text('New flow'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('New flow'));
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save master flow');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(find.text('FIRST HANDOVER'), findsOneWidget);
      Finder field(String hint) => find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == hint,
      );
      Future<void> reveal(Finder target) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          target,
          100,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await Scrollable.ensureVisible(tester.element(target), alignment: 0.25);
        await tester.pumpAndSettle();
      }

      await tester.enterText(field('Apartment finishes'), 'Apartment finishes');
      await tester.enterText(field('AF'), 'AF');
      await reveal(field('e.g. Plastering'));
      await tester.enterText(field('e.g. Plastering').first, 'Plastering');
      await reveal(find.byType(DropdownButtonFormField<String>).first);
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('PlasterCo').last);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      await reveal(find.text('Add activity'));
      await tester.tap(find.text('Add activity'));
      await tester.pumpAndSettle();
      await reveal(field('e.g. Plastering').last);
      await tester.enterText(field('e.g. Plastering').last, 'Painting');
      await reveal(find.byType(DropdownButtonFormField<String>).last);
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('PaintCo').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Move activity 2 up'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Move activity 2 up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save master flow'));
      await tester.pumpAndSettle();
      expect(result, 'Apartment finishes');
      final flows = await const MasterFlowStore(
        project: '1',
        company: '2',
      ).load();
      expect(flows.single.reference, 'AF');
      expect(flows.single.senderCompany, 'Apex Build');
      expect(flows.single.activities.map((item) => item['name']), [
        'Painting',
        'Plastering',
      ]);
      expect(flows.single.checkSheets.map((item) => item['number']), [
        '1',
        '2',
      ]);
      expect(flows.single.startingCompany, 'PaintCo');
      expect(tester.takeException(), isNull);
    });
  }
}
