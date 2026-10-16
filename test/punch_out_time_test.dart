import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/dashboard/domain/entity/inpunch_entity.dart';
import 'package:dropline/features/punch/presentation/pages/punch_out.dart';
import 'package:dropline/features/punch/presentation/widgets/punch_out_slide_bar.dart';
import 'package:dropline/features/punch/presentation/widgets/punch_time_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    sl.registerSingleton<SecureStorage>(
      SecureStorage(const FlutterSecureStorage()),
    );
  });
  tearDown(() => sl.reset());

  testWidgets('Calculates worked hours across dates and uses the current clock', (
    tester,
  ) async {
    final start = DateTime.now().subtract(
      const Duration(hours: 26, minutes: 5),
    );
    final stamp = start.toIso8601String();
    await sl<SecureStorage>().savePunchInResult([
      InPunchEntity(
        inpunchId: '1',
        projectId: '2',
        userId: '3',
        date: stamp.split('T').first,
        time: stamp.split('T').last,
        status: '1',
        projectName: 'Test project',
      ),
    ]);
    await tester.pumpWidget(const MaterialApp(home: PunchOutPage()));
    await tester.pumpAndSettle();
    final cards = tester
        .widgetList<PunchTimeCard>(find.byType(PunchTimeCard))
        .toList();
    expect(cards.last.time, '26:05');
    final now = DateTime.now();
    expect(
      tester.widget<PunchOutSlideBar>(find.byType(PunchOutSlideBar)).timeText,
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Missing punch-in data shows an unknown duration', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PunchOutPage()));
    await tester.pumpAndSettle();
    final cards = tester.widgetList<PunchTimeCard>(find.byType(PunchTimeCard));
    expect(cards.last.time, '--:--');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
