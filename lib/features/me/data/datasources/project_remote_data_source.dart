import 'dart:convert';

import 'package:dropline/core/api_constant/api_client.dart';
import 'package:dropline/core/api_constant/dio_client.dart';

import '../models/project_model.dart';

abstract class ProjectRemoteDataSource {
  Future<List<ProjectModel>> getProjects();
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final DioClient dioClient;

  ProjectRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<ProjectModel>> getProjects() async {
    final response = await dioClient.client.post(ApiClient.get_Project);

    final dynamic decoded = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (decoded is! Map) {
      throw const FormatException(
        'Invalid project response: expected an object',
      );
    }
    final data = Map<String, dynamic>.from(decoded);

    if (data['status'] == true) {
      final dynamic result = data['result'] ?? [];
      if (result is! List) {
        throw const FormatException('Invalid project result: expected a list');
      }

      return result.map((item) {
        if (item is! Map) {
          throw const FormatException(
            'Invalid project entry: expected an object',
          );
        }
        return ProjectModel.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    }

    throw Exception(data['message']?.toString() ?? 'Failed to fetch projects');
  }
}
