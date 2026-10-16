import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dropline/features/auth/data/model/login_response_model.dart';

class SecureStorage {
  final FlutterSecureStorage storage;
  static const loginResponseKey = 'login_response';

  SecureStorage(this.storage);

  SecureStorage.withStorage(FlutterSecureStorage storage) : this(storage);

  Future<void> saveLoginResponse(LoginResponseModel response) => storage.write(
    key: loginResponseKey,
    value: jsonEncode(response.toJson()),
  );

  Future<LoginResponseModel?> readLoginResponse() async {
    final value = await storage.read(key: loginResponseKey);
    if (value == null) return null;
    return LoginResponseModel.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  }

  Future<void> clearLoginResponse() => storage.delete(key: loginResponseKey);
}
