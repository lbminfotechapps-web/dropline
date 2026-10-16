import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/auth/data/datasource/login_remote_data_source.dart';
import 'package:dropline/features/auth/data/model/login_response_model.dart';
import 'package:dropline/features/auth/data/repositories/login_repository_impl.dart';
import 'package:dropline/features/auth/domain/usecases/login_usecase.dart';
import 'package:dropline/features/auth/presentation/bloc/login_bloc.dart';
import 'package:dropline/features/auth/presentation/bloc/login_event.dart';
import 'package:dropline/features/auth/presentation/bloc/login_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRemote implements LoginRemoteDataSource {
  final bool accepted;
  FakeRemote(this.accepted);

  @override
  Future<LoginResponseModel> login({
    required String name,
    required String mobileNumber,
    required String mobileInfo,
    required String fcmToken,
    required String otp,
  }) async => LoginResponseModel(
    status: accepted,
    message: accepted ? 'Welcome' : 'Invalid login',
    result: [],
    otp: otp,
  );
}

class FailingStorage extends SecureStorage {
  FailingStorage() : super.withStorage(const FlutterSecureStorage());

  @override
  Future<void> saveLoginResponse(LoginResponseModel response) async {
    throw Exception('Storage unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final accepted in [true, false]) {
    test(
      'Login accepted=$accepted persists only successful response',
      () async {
        final storage = SecureStorage.withStorage(const FlutterSecureStorage());
        final bloc = LoginBloc(
          LoginUseCase(LoginRepositoryImpl(FakeRemote(accepted), storage)),
        );
        addTearDown(bloc.close);
        final completed = bloc.stream.firstWhere(
          (state) => state.status != LoginStatus.loading,
        );
        bloc.add(
          const SubmitLoginEvent(name: 'Test', mobileNumber: '0712345678'),
        );
        final state = await completed;
        expect(
          state.status,
          accepted ? LoginStatus.success : LoginStatus.failure,
        );
        final saved = await storage.readLoginResponse();
        expect(saved?.toJson(), accepted ? state.response!.toJson() : null);
      },
    );
  }

  test('Storage failure prevents login success', () async {
    final bloc = LoginBloc(
      LoginUseCase(LoginRepositoryImpl(FakeRemote(true), FailingStorage())),
    );
    addTearDown(bloc.close);
    final completed = bloc.stream.firstWhere(
      (state) => state.status == LoginStatus.failure,
    );
    bloc.add(const SubmitLoginEvent(name: 'Test', mobileNumber: '0712345678'));
    expect((await completed).message, 'Storage unavailable');
  });
}
