import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dropline/core/api_constant/api_client.dart';
import '../../domain/entities/multiple_company_admin_entity.dart';
import '../models/multiple_company_admin_model.dart';

class MultipleCompanyAdminDatasource {
  final Dio dio;
  MultipleCompanyAdminDatasource(this.dio);

  Future<MultipleCompanyAdminModel> submit(
    MultipleCompanyAdminRequest request,
  ) async {
    final response = await dio.post(
      ApiClient.submitMultipleCompanyAdminOwner,
      data: FormData.fromMap({
        'login_user_id': request.loginUserId,
        'company_id': request.companyId,
        'project_id': request.projectId,
        'sub_company_id': request.subCompanyId,
        'admin_owner_arr': jsonEncode(
          request.people.map(MultipleCompanyAdminModel.personToJson).toList(),
        ),
      }),
    );
    final dynamic data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (data is! Map) {
      throw const FormatException('Invalid invitation response');
    }
    return MultipleCompanyAdminModel.fromJson(Map<String, dynamic>.from(data));
  }
}
