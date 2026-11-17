import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dropline/core/api_constant/api_client.dart';

class QrLoginDatasource {
  QrLoginDatasource(this._dio);

  final Dio _dio;
  static const endpoint = '${ApiClient.baseUrl}/approve_qr_login';

  Future<String> approve({
    required String loginId,
    required String mobileNo,
    required String token,
  }) async {
    final parameters = {
      'login_id': loginId,
      'mobile_no': mobileNo,
      'token': token.trim(),
    };
    debugPrint('QR login POST URL: $endpoint');
    debugPrint('QR login POST parameters: ${jsonEncode(parameters)}');
    final response = await _dio.post<dynamic>(
      endpoint,
      data: parameters,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (data is! Map) {
      throw const FormatException('Invalid QR login response.');
    }
    final message = data['message']?.toString().trim() ?? '';
    if (data['status'] != true && data['status']?.toString() != '1') {
      throw FormatException(
        message.isEmpty ? 'Unable to approve QR login.' : message,
      );
    }
    return message.isEmpty ? 'QR login approved successfully.' : message;
  }
}
