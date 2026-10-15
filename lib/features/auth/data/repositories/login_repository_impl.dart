import 'package:dropline/features/auth/data/datasource/login_remote_data_source.dart';
import 'package:dropline/features/auth/data/model/login_response_model.dart';

import '../../domain/repositories/login_repository.dart';

class LoginRepositoryImpl implements LoginRepository {
  final LoginRemoteDataSource remoteDataSource;

  LoginRepositoryImpl(this.remoteDataSource);

  @override
  Future<LoginResponseModel> login({
    required String name,
    required String mobileNumber,
    required String mobileInfo,
    required String fcmToken,
    required String otp,
  }) {
    return remoteDataSource.login(
      name: name,
      mobileNumber: mobileNumber,
      mobileInfo: mobileInfo,
      fcmToken: fcmToken,
      otp: otp,
    );
  }
}
