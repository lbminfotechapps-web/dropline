import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/auth/data/datasource/login_remote_data_source.dart';
import 'package:dropline/features/auth/data/model/login_response_model.dart';

import '../../domain/repositories/login_repository.dart';

class LoginRepositoryImpl implements LoginRepository {
  final LoginRemoteDataSource remoteDataSource;

  final SecureStorage secureStorage;

  LoginRepositoryImpl(this.remoteDataSource, this.secureStorage);

  @override
  Future<LoginResponseModel> login({
    required String name,
    required String mobileNumber,
    required String mobileInfo,
    required String fcmToken,
    required String otp,
  }) async {
    final response = await remoteDataSource.login(
      name: name,
      mobileNumber: mobileNumber,
      mobileInfo: mobileInfo,
      fcmToken: fcmToken,
      otp: otp,
    );
    if (response.status) {
      await secureStorage.saveLoginResponse(response);
    }
    return response;
  }
}
