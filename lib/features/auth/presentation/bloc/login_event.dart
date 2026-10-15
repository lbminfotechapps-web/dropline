import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class SubmitLoginEvent extends LoginEvent {
  final String name;
  final String mobileNumber;
  final String mobileInfo;
  final String fcmToken;
  final String otp;

  const SubmitLoginEvent({
    required this.name,
    required this.mobileNumber,
    this.mobileInfo = 'test',
    this.fcmToken = '',
    this.otp = '',
  });

  @override
  List<Object?> get props => [name, mobileNumber, mobileInfo, fcmToken, otp];
}
