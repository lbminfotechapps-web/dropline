import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/dashboard/data/datasource/dashboard_datasource.dart';
import 'package:dropline/features/dashboard/domain/entity/inpunch_entity.dart';

import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:dropline/features/dashboard/domain/repository/dashboard_repo.dart';
import 'package:flutter/material.dart';

class DashboardRepoImp implements DashboardRepo {
  final DashboardDatasource dashboardDatasource;
  final SecureStorage secureStorage;

  DashboardRepoImp(this.dashboardDatasource, this.secureStorage);

  @override
  Future<ProjectResponseEntity> getProjects() async {
    return await dashboardDatasource.getProjects();
  }

  @override
  Future<InPunchResponseEntity> punchIn(
    String loginUserId,
    String projectName,
    String projectId,
    String type,
    String id,
  ) async {
    final response = await dashboardDatasource.punchIn(
      loginUserId,
      projectName,
      projectId,
      type,
      id,
    );

    // Save only when Punch In is successful.
    if (response.status && response.result.isNotEmpty) {
      await secureStorage.savePunchInResult(response.result);

      debugPrint('Punch In result saved securely.');
    }

    return response;
  }
}
