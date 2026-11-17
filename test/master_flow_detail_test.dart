import 'package:dropline/features/masterFlow/data/master_flow_store.dart';
import 'package:dropline/features/masterFlow/presentation/pages/master_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('flow item opens details and can start area selection', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await const MasterFlowStore(project: 'p', company: 'c').save(
      const SavedMasterFlow(
        name: 'Apartment finishes', reference: 'AF', senderCompany: 'Apex Build',
        activities: [
          {'name': 'Plastering', 'reference': 'PL-01', 'company': 'PlasterCo'},
          {'name': 'Touch-ups', 'reference': 'PL-02', 'company': 'PlasterCo'},
        ],
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: MasterFlowsScreen(projectId: 'p', companyId: 'c')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apartment finishes'));
    await tester.pumpAndSettle();
    expect(find.text('Edit flow'), findsOneWidget);
    expect(find.text('Master flow · Ref AF'), findsOneWidget);
    expect(find.text('PL-02 · PlasterCo · Visit 2'), findsOneWidget);
    expect(find.text('In CS-03 · Out CS-04'), findsOneWidget);
    await tester.tap(find.text('Use this flow'));
    await tester.pumpAndSettle();
    expect(find.text('Choose area'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
