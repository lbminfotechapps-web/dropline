import 'package:dio/dio.dart';
import 'package:dropline/core/api_constant/api_client.dart';
import 'package:dropline/core/api_constant/dio_client.dart';
import 'package:flutter/material.dart';

class ProjectDatasource {
  final DioClient dioClient;

  ProjectDatasource(this.dioClient);
  Future<void> addProject(
    String userId,
    String projectType,
    String projectName,
    String companyId,
    String companyName,
  ) async {
    try {
      debugPrint('add project request');

      final response = await dioClient.client.post(
        ApiClient.submitProject,
        data: FormData.fromMap({
          'login_user_id': userId,
          'project_type': projectType,
          'project_name': projectName,
          'company_id': companyId,
          'new_company_name': companyName,
        }),
      );

      debugPrint('add project response: ${response.data}');

      debugPrint('Status code: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('Dio error: ${e.message}');

      debugPrint('Response: ${e.response?.data}');

      debugPrint('Status: ${e.response?.statusCode}');

      throw Exception('Failed to add project: ${e.message}');
    } catch (e) {
      debugPrint('add project error: $e');

      throw Exception('Failed to add project: $e');
    }
  }
}
