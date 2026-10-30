import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dropline/core/api_constant/api_client.dart';
import '../models/sub_company_model.dart';

abstract class SubCompanyDatasource {
  Future<List<SubCompanyModel>> getSubCompanies({
    required String projectId,
    String subCompanyName = '',
    String companyId = '',
  });
  Future<SubCompanyModel> submitSubCompany({
    required String loginUserId,
    required String companyId,
    required String projectId,
    required String tradeId,
    required String subCompanyName,
  });
}

class SubCompanyDatasourceImpl implements SubCompanyDatasource {
  final Dio dio;

  SubCompanyDatasourceImpl(this.dio);

  @override
  Future<List<SubCompanyModel>> getSubCompanies({
    required String projectId,
    String subCompanyName = '',
    String companyId = '',
  }) async {
    if (projectId.trim().isEmpty)
      throw Exception('Please reopen the selected project from Me.');
    final response = await dio.post(
      ApiClient.getSubCompany,
      data: FormData.fromMap({
        'project_id': projectId,
        if (subCompanyName.trim().isNotEmpty)
          'subcompany_name': subCompanyName.trim(),
        if (companyId.trim().isNotEmpty) 'company_id': companyId.trim(),
      }),
    );
    final dynamic data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (data is! Map)
      throw const FormatException('Invalid subcompany response');
    if (data['status'] != true)
      throw Exception(
        data['message']?.toString() ?? 'Failed to load companies',
      );
    final dynamic result = data['result'];
    if (result is! List) throw const FormatException('Invalid subcompany list');
    return result.map((item) {
      if (item is! Map) throw const FormatException('Invalid subcompany entry');
      return SubCompanyModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  @override
  Future<SubCompanyModel> submitSubCompany({
    required String loginUserId,
    required String companyId,
    required String projectId,
    required String tradeId,
    required String subCompanyName,
  }) async {
    try {
      final params = <String, String>{
        'login_user_id': loginUserId,
        'company_id': companyId,
        'project_id': projectId,
        'trade_id': tradeId,
        'subcompany_name': subCompanyName,
      };

      print('SUB COMPANY POST PARAMETERS: $params');

      final response = await dio.post(
        ApiClient.submit_sub_company,
        data: FormData.fromMap(params),
      );

      final dynamic decoded = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      if (decoded is! Map) {
        throw const FormatException('Invalid sub company response');
      }
      final data = Map<String, dynamic>.from(decoded);

      if (data['status'] == true) {
        final result = data['result'];

        if (result is List && result.isNotEmpty) {
          return SubCompanyModel.fromJson(
            Map<String, dynamic>.from(result.first as Map),
          );
        }

        throw Exception('Sub company details not found');
      }

      throw Exception(
        data['message']?.toString() ?? 'Failed to submit sub company',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? (e.response?.data['message']?.toString() ??
                  e.message ??
                  'Network error')
            : (e.message ?? 'Network error'),
      );
    }
  }
}
