import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/features/me/domain/entities/project_entity.dart';
import 'package:dropline/features/me/domain/repositories/project_repository.dart';
import 'package:dropline/features/me/domain/usecases/get_projects_usecase.dart';
import 'package:dropline/features/me/presentation/bloc/project_bloc.dart';
import 'package:dropline/features/me/presentation/pages/me.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Projects extends ProjectRepository {
  @override
  Future<List<ProjectEntity>> getProjects() async => const [
    ProjectEntity(
      projectId: '1',
      projectName: 'Sample project',
      companyId: '1',
      projectType: 'Business',
      companyName: 'Sample company',
    ),
  ];
}

void main() {
  for (final size in [const Size(360, 740), const Size(390, 844)]) {
    testWidgets('Workspace shows projects without scrolling at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      sl.registerFactory<ProjectBloc>(
        () => ProjectBloc(GetProjectsUseCase(_Projects())),
      );
      addTearDown(() => sl.reset());
      await tester.pumpWidget(const MaterialApp(home: MePage()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sample project').hitTestable(), findsOneWidget);
      expect(
        tester.getBottomRight(find.text('Sample company')).dy,
        lessThan(size.height - 100),
      );

      await tester.tap(find.byTooltip('Choose language'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, 'Hindi'));
      await tester.pumpAndSettle();
      expect(find.text('HI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
