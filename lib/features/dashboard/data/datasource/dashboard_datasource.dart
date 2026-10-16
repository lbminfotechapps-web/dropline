import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dropline/core/api_constant/api_client.dart';
import 'package:dropline/core/api_constant/dio_client.dart';
import 'package:dropline/features/dashboard/data/model/project_model.dart';

class DashboardDatasource {
  final DioClient dioClient;

  DashboardDatasource(this.dioClient);

  Future<ProjectResponseModel> getProjects() async {
    try {
      final response = await dioClient.client.post(ApiClient.getProject);

      print('Project response: ${response.data}');
      print('Response type: ${response.data.runtimeType}');
      print('Api url: ${ApiClient.getProject}');
      final Map<String, dynamic> jsonData = jsonDecode(
        response.data.toString(),
      );
      return ProjectResponseModel.fromJson(jsonData);
    } on DioException catch (e) {
      print('Dio error: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status: ${e.response?.statusCode}');

      throw Exception('Failed to login: ${e.message}');
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }
}
