import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/company_admin_entity.dart';
import '../../domain/usecase/submit_company_admin_usecase.dart';

class SubmitCompanyAdminEvent {
  final CompanyAdminRequest request;
  const SubmitCompanyAdminEvent(this.request);
}

class CompanyAdminState {
  final bool loading;
  final CompanyAdminEntity? admin;
  final String? error;
  const CompanyAdminState({this.loading = false, this.admin, this.error});
}

class CompanyAdminBloc
    extends Bloc<SubmitCompanyAdminEvent, CompanyAdminState> {
  CompanyAdminBloc(SubmitCompanyAdminUsecase submit)
    : super(const CompanyAdminState()) {
    on<SubmitCompanyAdminEvent>((event, emit) async {
      if (state.loading) return;
      emit(const CompanyAdminState(loading: true));
      try {
        emit(CompanyAdminState(admin: await submit(event.request)));
      } catch (error) {
        emit(
          CompanyAdminState(
            error: error.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    });
  }
}
