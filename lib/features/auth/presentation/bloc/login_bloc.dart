import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropline/features/auth/domain/usecases/login_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;

  LoginBloc(this.loginUseCase) : super(const LoginState()) {
    on<SubmitLoginEvent>((event, emit) async {
      if (state.status == LoginStatus.loading) return;
      emit(const LoginState(status: LoginStatus.loading));
      try {
        final response = await loginUseCase(
          name: event.name,
          mobileNumber: event.mobileNumber,
          mobileInfo: event.mobileInfo,
          fcmToken: event.fcmToken,
          otp: event.otp,
        );
        emit(
          LoginState(
            status: response.status ? LoginStatus.success : LoginStatus.failure,
            message: response.message.isEmpty && !response.status
                ? 'Login failed. Please try again.'
                : response.message,
            response: response,
          ),
        );
      } catch (error) {
        emit(
          LoginState(
            status: LoginStatus.failure,
            message: error.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    });
  }
}
