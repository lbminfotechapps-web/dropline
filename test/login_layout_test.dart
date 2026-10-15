import 'package:dropline/features/auth/presentation/pages/loginpage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('Terms dialog uses native controls on $platform', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: const LoginScreen(),
        ),
      );
      final link = find.text('Terms & Conditions');
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(
        find.byType(
          platform == TargetPlatform.iOS ? CupertinoAlertDialog : AlertDialog,
        ),
        findsOneWidget,
      );
      expect(find.text('I agree').hitTestable(), findsOneWidget);
      await tester.tap(find.text('I agree'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final size in [const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Login remains reachable with the keyboard at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      final title = find.text('Sign in');
      final titleHeight = tester.getSize(title).height;
      await tester.tap(find.byType(TextField).first);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(tester.getSize(title).height, titleHeight);
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNWidgets(2));
      final mobile = find.byType(TextField).at(1);
      await tester.enterText(mobile, '071234567');
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(mobile, '0712345678');
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(6));
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 6; i++) {
        final field = find.byType(TextField).at(i);
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        expect(field.hitTestable(), findsOneWidget);
      }

      // Scroll without dismissing the keyboard and check the entire action.
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      final action = find.text('SLIDE TO SIGN IN');
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(action).dy, lessThan(size.height - 300));
      expect(tester.takeException(), isNull);
      await tester.enterText(mobile, '071234567');
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
