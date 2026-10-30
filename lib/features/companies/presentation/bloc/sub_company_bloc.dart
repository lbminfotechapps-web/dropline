import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecase/submit_sub_company_usecase.dart';
import 'sub_company_event.dart';
import 'sub_company_state.dart';

class SubCompanyBloc extends Bloc<SubCompanyEvent, SubCompanyState> {
  final SubmitSubCompanyUsecase submitSubCompanyUsecase;

  SubCompanyBloc(this.submitSubCompanyUsecase) : super(SubCompanyInitial()) {
    on<SubmitSubCompanyEvent>(_submitSubCompany);
  }

  Future<void> _submitSubCompany(
    SubmitSubCompanyEvent event,
    Emitter<SubCompanyState> emit,
  ) async {
    emit(SubCompanyLoading());

    try {
      final result = await submitSubCompanyUsecase(
        loginUserId: event.loginUserId,
        companyId: event.companyId,
        projectId: event.projectId,
        tradeId: event.tradeId,
        subCompanyName: event.subCompanyName,
      );

      emit(SubCompanySuccess(result));
    } catch (e) {
      emit(SubCompanyError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
