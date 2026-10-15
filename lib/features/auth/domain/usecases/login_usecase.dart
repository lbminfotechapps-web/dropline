import 'package:dropline/features/auth/data/model/login_response_model.dart';

import '../repositories/login_repository.dart';

class LoginUseCase {
  final LoginRepository repository;

  LoginUseCase(this.repository);

  Future<LoginResponseModel> call({
    required String name,
    required String mobileNumber,
    required String mobileInfo,
    required String fcmToken,
    required String otp,
  }) {
    return repository.login(
      name: name,
      mobileNumber: mobileNumber,
      mobileInfo: mobileInfo,
      fcmToken: fcmToken,
      otp: otp,
    );
  }
}
