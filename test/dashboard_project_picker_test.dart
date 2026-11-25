import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropline/features/dashboard/data/model/project_model.dart';
import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:dropline/features/dashboard/domain/usecase/dashboard_usecase.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:dropline/features/dashboard/presentation/widgets/dashboard_project_card.dart';
import 'package:dropline/features/newproject/presentation/pages/new_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Projects extends Fake implements DashboardUsecase {
  @override
  Future<ProjectResponseEntity> getProjects() async => ProjectResponseEntity(
    status: true,
    message: '',
    result: [
      ProjectModel.fromJson({
        'fld_project_id': '1',
        'fld_project_name': 'Office',
        'fld_project_type': 'Business',
      }),
    ],
  );
}

void main() {
  testWidgets('Dashboard switch updates the palette and saves the choice', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    sl.registerSingleton<SecureStorage>(
      SecureStorage(const FlutterSecureStorage()),
    );
    addTearDown(() => sl.unregister<SecureStorage>());
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = DashboardBloc(_Projects());
    final controller = AppThemeController();
    addTearDown(bloc.close);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: controller,
        child: BlocProvider.value(
          value: bloc,
          child: ValueListenableBuilder<bool>(
            valueListenable: controller.whiteTheme,
            builder: (context, enabled, child) => MaterialApp(
              theme: ThemeData(
                extensions: [if (enabled) const WhiteAppTheme()],
              ),
              themeAnimationDuration: Duration.zero,
              home: child,
            ),
            child: const DashboardPage(),
          ),
        ),
      ),
    );

    Color? dashboardBackground() =>
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;

    final whiteTheme = find.byType(Switch);
    expect(dashboardBackground(), AppColors.background);
    await tester.tap(whiteTheme);
    await tester.pumpAndSettle();
    expect(dashboardBackground(), WhiteAppTheme.background);
    expect(tester.widget<Switch>(whiteTheme).value, isTrue);

    final restored = AppThemeController();
    addTearDown(restored.dispose);
    await tester.pump();
    expect(restored.whiteTheme.value, isTrue);

    await tester.tap(whiteTheme);
    await tester.pumpAndSettle();
    expect(dashboardBackground(), AppColors.background);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Picker labels project types and retains newly added projects', (
    tester,
  ) async {
    final bloc = DashboardBloc(_Projects());
    addTearDown(bloc.close);
    ProjectEntity? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: Scaffold(
            body: DashboardProjectCard(
              onProjectSelected: (project) => selected = project,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Select project'));
    await tester.pumpAndSettle();
    expect(find.text('Office'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Business').first);
    await tester.pumpAndSettle();
    expect(find.byType(NewProjectPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(NewProjectPage))).pop();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'New site');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(selected?.projectName, 'New site');
    expect(selected?.typeLabel, 'Personal');
    await tester.tap(find.text('Select project'));
    await tester.pumpAndSettle();
    expect(find.text('New site'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
