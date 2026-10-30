import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/multiple_company_admin_entity.dart';
import '../../domain/usecase/submit_multiple_company_admin_usecase.dart';

class MultipleCompanyAdminState {
  final bool loading;
  final MultipleCompanyAdminResult? result;
  final String? error;
  const MultipleCompanyAdminState({
    this.loading = false,
    this.result,
    this.error,
  });
}

class MultipleCompanyAdminCubit extends Cubit<MultipleCompanyAdminState> {
  final SubmitMultipleCompanyAdminUsecase submitAdmins;
  MultipleCompanyAdminCubit(this.submitAdmins)
    : super(const MultipleCompanyAdminState());
  Future<void> submit(MultipleCompanyAdminRequest request) async {
    if (state.loading) return;
    emit(const MultipleCompanyAdminState(loading: true));
    try {
      final result = await submitAdmins(request);
      if (!isClosed) emit(MultipleCompanyAdminState(result: result));
    } catch (error) {
      if (!isClosed) {
        emit(
          MultipleCompanyAdminState(
            error: error.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    }
  }
}
