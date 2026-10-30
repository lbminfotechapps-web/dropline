import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dropline/core/api_constant/api_client.dart';
import '../../domain/entities/company_admin_entity.dart';
import '../models/company_admin_model.dart';

class CompanyAdminDatasource {
  final Dio dio;
  CompanyAdminDatasource(this.dio);
  Future<List<CompanyAdminModel>> getPendingInvitations({
    required String loginUserId,
    required String projectId,
  }) async {
    final response = await dio.post(
      ApiClient.getAdminPendingInvitation,
      data: FormData.fromMap({
        'login_user_id': loginUserId,
        'project_id': projectId,
      }),
    );
    final dynamic data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (data is! Map)
      throw const FormatException('Invalid pending invitations response');
    if (data['status'] != true) {
      throw Exception(
        data['message']?.toString() ?? 'Unable to load pending invitations',
      );
    }
    final dynamic result = data['result'];
    if (result is! List)
      throw const FormatException('Invalid pending invitations list');
    return result.map((item) {
      if (item is! Map)
        throw const FormatException('Invalid pending invitation');
      return CompanyAdminModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<CompanyAdminModel> updateInvitation({
    required String loginUserId,
    required String adminOwnerId,
  }) async {
    final response = await dio.post(
      ApiClient.update_admin_invitation,
      data: FormData.fromMap({
        'login_user_id': loginUserId,
        'admin_owner_id': adminOwnerId,
      }),
    );
    final dynamic data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (data is! Map)
      throw const FormatException('Invalid invitation response');
    if (data['status'] != true) {
      throw Exception(
        data['message']?.toString() ?? 'Unable to update invitation',
      );
    }
    final dynamic result = data['result'];
    if (result is! List || result.isEmpty || result.first is! Map) {
      throw const FormatException('Updated admin details not found');
    }
    return CompanyAdminModel.fromJson(
      Map<String, dynamic>.from(result.first as Map),
    );
  }

  Future<CompanyAdminModel> submit(CompanyAdminRequest request) async {
    try {
      final response = await dio.post(
        ApiClient.submit_company_admin_owner,
        data: FormData.fromMap({
          'login_user_id': request.loginUserId,
          'company_id': request.companyId,
          'project_id': request.projectId,
          'sub_company_id': request.subCompanyId,
          'admin_owner_name': request.name,
          'mobile_no': request.mobile,
          'role_id': request.roleId,
          'task_define_arr': jsonEncode(
            request.tasks.entries
                .map(
                  (task) => {
                    'task_define_id': task.key,
                    'flag': task.value ? 1 : 0,
                  },
                )
                .toList(),
          ),
        }),
      );
      final dynamic data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      if (data is! Map) throw const FormatException('Invalid admin response');
      if (data['status'] != true)
        throw Exception(
          data['message']?.toString() ?? 'Unable to create admin',
        );
      final dynamic result = data['result'];
      if (result is! List || result.isEmpty || result.first is! Map)
        throw const FormatException('Admin details not found');
      return CompanyAdminModel.fromJson(
        Map<String, dynamic>.from(result.first as Map),
      );
    } on DioException catch (error) {
      final dynamic data = error.response?.data;
      throw Exception(
        data is Map
            ? data['message']?.toString() ?? 'Unable to create admin'
            : error.message ?? 'Network error',
      );
    }
  }
}
