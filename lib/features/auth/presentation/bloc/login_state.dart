import 'package:equatable/equatable.dart';
import 'package:dropline/features/auth/data/model/login_response_model.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String message;
  final LoginResponseModel? response;

  const LoginState({
    this.status = LoginStatus.initial,
    this.message = '',
    this.response,
  });

  @override
  List<Object?> get props => [status, message, response];
}
