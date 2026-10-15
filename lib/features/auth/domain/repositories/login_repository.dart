import 'package:dropline/features/auth/data/model/login_response_model.dart';

abstract class LoginRepository {
  Future<LoginResponseModel> login({
    required String name,
    required String mobileNumber,
    required String mobileInfo,
    required String fcmToken,
    required String otp,
  });
}
