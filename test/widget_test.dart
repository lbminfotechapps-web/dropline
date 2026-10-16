import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/auth/data/datasource/login_remote_data_source.dart';
import 'package:dropline/features/auth/data/model/login_response_model.dart';
import 'package:dropline/features/auth/presentation/pages/loginpage.dart';
import 'package:dropline/features/auth/presentation/pages/choose_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class SuccessfulLoginRemote implements LoginRemoteDataSource {
  String? submittedMobile;
  @override
  Future<LoginResponseModel> login({
    required String name,
    required String mobileNumber,
    required String mobileInfo,
    required String fcmToken,
    required String otp,
  }) async {
    submittedMobile = mobileNumber;
    return const LoginResponseModel(
      status: true,
      message: 'Welcome',
      result: [],
      otp: '',
    );
  }
}

void main() {
  testWidgets('Sign in saves the response before opening the dashboard', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    await initGlobalDi();
    addTearDown(() => sl.reset());
    final remote = SuccessfulLoginRemote();
    sl.unregister<LoginRemoteDataSource>();
    sl.registerSingleton<LoginRemoteDataSource>(remote);
    final router = GoRouter(
      initialLocation: AppRouter.login,
      routes: [
        GoRoute(path: AppRouter.login, builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: AppRouter.chooseOption,
          builder: (_, _) => const ChooseOptionPage(),
        ),
        GoRoute(
          path: AppRouter.dashboard,
          builder: (_, _) => const Scaffold(body: Text('Dashboard opened')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.enterText(find.byType(TextField).first, 'Test User');
    await tester.enterText(find.byType(TextField).at(1), '0712345678');
    await tester.pumpAndSettle();
    final signIn = find.text('SLIDE TO SIGN IN');
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pumpAndSettle();
    expect(
      find.text('Please agree to the Terms & Conditions to continue.'),
      findsOneWidget,
    );
    expect(remote.submittedMobile, isNull);
    await tester.tap(find.text('Terms & Conditions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I agree'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pumpAndSettle();
    expect(find.text('Signed in successfully.'), findsOneWidget);
    expect(find.text('PERSONAL'), findsOneWidget);
    await tester.tap(find.text('BUSINESS'));
    await tester.pumpAndSettle();
    expect(find.text('Business is coming soon.'), findsOneWidget);
    expect(find.text('PERSONAL'), findsOneWidget);
    await tester.tap(find.text('PERSONAL'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard opened'), findsOneWidget);
    expect(remote.submittedMobile, '0712345678');
    expect((await sl<SecureStorage>().readLoginResponse())?.status, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
