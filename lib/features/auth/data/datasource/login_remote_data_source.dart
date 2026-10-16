import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:dropline/core/api_constant/api_client.dart';
import 'package:dio/dio.dart';
import 'package:dropline/features/auth/data/model/login_response_model.dart';

abstract class LoginRemoteDataSource {
  Future<LoginResponseModel> login({
    required String name,
    required String mobileNumber,
    required String mobileInfo,
    required String fcmToken,
    required String otp,
  });
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final Dio dio;

  LoginRemoteDataSourceImpl(this.dio);

  @override
  Future<LoginResponseModel> login({
    required String name,
    required String mobileNumber,
    required String mobileInfo,
    required String fcmToken,
    required String otp,
  }) async {
    try {
      final response = await dio.post(
        ApiClient.login,
        data: {
          'name': name,
          'mobile_number': mobileNumber,
          'mobile_info': mobileInfo,
          'fcm_token': fcmToken,
          'otp': otp,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (kDebugMode) {
        debugPrint('LOGIN RESPONSE (${response.statusCode}): ${response.data}');
      }

      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (data is! Map) {
        throw Exception('Invalid server response');
      }

      return LoginResponseModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timed out. Please try again.');
      }

      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server.');
      }

      throw Exception(
        'Login request failed: ${e.response?.statusCode ?? e.message}',
      );
    }
  }
}
