import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dropline/core/api_constant/api_client.dart';
import 'package:dropline/core/api_constant/dio_client.dart';
import 'package:dropline/features/dashboard/data/model/inpunch_response_entity.dart';
import 'package:dropline/features/dashboard/data/model/project_model.dart';
import 'package:flutter/material.dart';

class DashboardDatasource {
  final DioClient dioClient;

  DashboardDatasource(this.dioClient);

  Future<ProjectResponseModel> getProjects() async {
    try {
      final response = await dioClient.client.post(ApiClient.getProject);

      print('Project API URL: ${response.requestOptions.uri}');
      print('Project response: ${response.data}');
      print('Response type: ${response.data.runtimeType}');

      final dynamic data = response.data;

      late final Map<String, dynamic> jsonData;

      if (data is Map<String, dynamic>) {
        jsonData = data;
      } else if (data is Map) {
        jsonData = Map<String, dynamic>.from(data);
      } else if (data is String) {
        final decoded = jsonDecode(data);

        if (decoded is! Map) {
          throw const FormatException('Invalid project response format');
        }

        jsonData = Map<String, dynamic>.from(decoded);
      } else {
        throw const FormatException('Unsupported project response format');
      }

      return ProjectResponseModel.fromJson(jsonData);
    } on DioException catch (e) {
      print('Project API error: ${e.message}');
      print('Response: ${e.response?.data}');
      print('HTTP Status: ${e.response?.statusCode}');

      throw Exception(
        'Failed to load projects: '
        '${e.response?.statusMessage ?? e.message ?? "Network error"}',
      );
    } catch (e) {
      print('Project parsing error: $e');
      rethrow;
    }
  }

  Future<InPunchResponseModel> punchIn(
    String loginUserId,
    String projectName,
    String projectId,
    String type,
    String id,
  ) async {
    try {
      debugPrint('========== PUNCH IN REQUEST ==========');
      debugPrint('API URL: ${ApiClient.punchIn}');

      // Print POST parameters
      debugPrint('login_user_id: $loginUserId');
      debugPrint('project_name: $projectName');
      debugPrint('project_id: $projectId');

      final formData = FormData.fromMap({
        'login_user_id': loginUserId,
        'project_name': projectName,
        'project_id': projectId,
        'type': type,
        'inpunch_id': id,
      });

      // API Call
      final response = await dioClient.client.post(
        ApiClient.punchIn,
        data: formData,
      );

      debugPrint('========== PUNCH IN RESPONSE ==========');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('Response Type: ${response.data.runtimeType}');

      // Convert response into Map
      final dynamic data = response.data;

      late final Map<String, dynamic> jsonData;

      if (data is Map<String, dynamic>) {
        jsonData = data;
      } else if (data is Map) {
        jsonData = Map<String, dynamic>.from(data);
      } else if (data is String) {
        final decoded = jsonDecode(data);

        if (decoded is! Map) {
          throw const FormatException('Invalid Punch In API response');
        }

        jsonData = Map<String, dynamic>.from(decoded);
      } else {
        throw const FormatException('Unsupported Punch In response format');
      }

      // Convert JSON into Model
      final punchInResponse = InPunchResponseModel.fromJson(jsonData);

      debugPrint('Punch In Status: ${punchInResponse.status}');
      debugPrint('Message: ${punchInResponse.message}');

      if (punchInResponse.result.isNotEmpty) {
        final punch = punchInResponse.result.first;

        debugPrint('InPunch ID: ${punch.inpunchId}');
        debugPrint('Project ID: ${punch.projectId}');
        debugPrint('User ID: ${punch.userId}');
        debugPrint('Project Name: ${punch.projectName}');
        debugPrint('Date: ${punch.date}');
        debugPrint('Time: ${punch.time}');
        debugPrint('Status: ${punch.status}');
      }

      // Return Model
      return punchInResponse;
    } on DioException catch (e) {
      debugPrint('========== PUNCH IN DIO ERROR ==========');
      debugPrint('Error: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Status Code: ${e.response?.statusCode}');

      throw Exception('Failed to Punch In: ${e.message}');
    } catch (e) {
      debugPrint('========== PUNCH IN ERROR ==========');
      debugPrint('Error: $e');

      rethrow;
    }
  }
}
