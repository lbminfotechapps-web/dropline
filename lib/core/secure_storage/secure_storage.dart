import 'dart:convert';

import 'package:dropline/features/dashboard/data/model/inpunch_response_entity.dart';
import 'package:dropline/features/dashboard/domain/entity/inpunch_entity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dropline/features/auth/data/model/login_response_model.dart';

class SecureStorage {
  final FlutterSecureStorage storage;
  static const loginResponseKey = 'login_response';

  static const punchInResponseKey = 'punch_in_result';

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

  Future<String> getUserId() async {
    final response = await readLoginResponse();

    if (response == null || response.result.isEmpty) {
      return '';
    }

    return response.result.first.userId;
  }

  Future<void> clearLoginResponse() => storage.delete(key: loginResponseKey);

  Future<void> savePunchInResult(List<InPunchEntity> result) async {
    final jsonList = result.map((punch) {
      return {
        'fld_inpunch_id': punch.inpunchId,
        'fld_project_id': punch.projectId,
        'fld_user_id': punch.userId,
        'fld_date': punch.date,
        'fld_time': punch.time,
        'fld_status': punch.status,
        'fld_project_name': punch.projectName,
      };
    }).toList();

    await storage.write(key: punchInResponseKey, value: jsonEncode(jsonList));
  }

  Future<List<InPunchEntity>> readPunchInResult() async {
    final value = await storage.read(key: punchInResponseKey);

    if (value == null || value.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(value) as List<dynamic>;

    return decoded.map((item) {
      return InPunchModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  // Get saved InPunch ID
  Future<String> getInPunchId() async {
    final result = await readPunchInResult();

    if (result.isEmpty) return '';

    return result.first.inpunchId;
  }

  // Get saved project ID
  Future<String> getPunchProjectId() async {
    final result = await readPunchInResult();

    if (result.isEmpty) return '';

    return result.first.projectId;
  }

  // Clear Punch In result
  Future<void> clearPunchInResult() async {
    await storage.delete(key: punchInResponseKey);
  }
}
