import 'dart:convert';

import 'package:dropline/features/masterFlow/presentation/pages/handovers_page.dart';
import 'package:dropline/features/masterFlow/data/master_flow_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(414, 796)]) {
    testWidgets('handovers create, open and persist at $size', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await const MasterFlowStore(project: '1', company: '2').save(
        const SavedMasterFlow(
          name: 'Apartment finishes',
          activities: [
            {'name': 'Plastering', 'reference': 'P1', 'company': 'Apex Build'},
            {'name': 'Painting', 'reference': 'P2', 'company': 'Apex Build'},
          ],
        ),
      );
      await const MasterFlowStore(
        project: 'other',
        company: '2',
      ).save(const SavedMasterFlow(name: 'Other project flow', activities: []));
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const page = MaterialApp(
        home: HandoversPage(
          projectId: '1',
          companyId: '2',
          projectName: 'Laxmi Gauri',
          companyName: 'Apex Build',
        ),
      );
      await tester.pumpWidget(page);
      await tester.pumpAndSettle();
      expect(
        find.text('No handovers yet. Start a handover to add an area.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Start handover'));
      await tester.pumpAndSettle();
      expect(find.text('Select flow'), findsOneWidget);
      expect(find.text('1. Flow'), findsOneWidget);
      expect(find.text('2. Area'), findsOneWidget);
      expect(find.text('3. Send'), findsOneWidget);
      expect(find.text('Apex Build starts · 2 activities'), findsOneWidget);
      expect(find.text('Other project flow'), findsNothing);
      await tester.tap(find.text('Apartment finishes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('Enter an area'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Building A › Level 03 › Apartment 305',
      );

      await tester.ensureVisible(find.text('Start'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('Awaiting acceptance'), findsOneWidget);
      expect(find.text('Apartment finishes'), findsOneWidget);
      await tester.tap(find.text('To do'));
      await tester.pumpAndSettle();
      expect(find.text('Apartment finishes'), findsOneWidget);
      await tester.ensureVisible(find.text('View area'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View area'));
      await tester.pumpAndSettle();
      expect(find.text('Building A › Level 03 › Apartment 305'), findsWidgets);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page);
      await tester.pumpAndSettle();
      expect(find.text('Apartment finishes'), findsOneWidget);
      final preferences = await SharedPreferences.getInstance();
      final saved =
          jsonDecode(preferences.getString('project_handovers_v1:["1","2"]')!)
              as List;
      expect(saved.single['company'], 'Apex Build');
    });
  }
}
