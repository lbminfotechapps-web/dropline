import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sub_company_entity.dart';
import '../../domain/usecase/get_sub_companies_usecase.dart';

class SearchSubCompanies {
  final String projectId;
  final String subCompanyName;
  final String companyId;
  const SearchSubCompanies({
    required this.projectId,
    this.subCompanyName = '',
    this.companyId = '',
  });
}

class FindCompanyState {
  final bool loading;
  final List<SubCompanyEntity> companies;
  final String? error;
  const FindCompanyState({
    this.loading = false,
    this.companies = const [],
    this.error,
  });
}

class FindCompanyBloc extends Bloc<SearchSubCompanies, FindCompanyState> {
  final GetSubCompaniesUsecase getCompanies;
  int _request = 0;
  FindCompanyBloc(this.getCompanies) : super(const FindCompanyState()) {
    on<SearchSubCompanies>((event, emit) async {
      final request = ++_request;
      emit(const FindCompanyState(loading: true));
      try {
        final companies = await getCompanies(
          projectId: event.projectId,
          subCompanyName: event.subCompanyName,
          companyId: event.companyId,
        );
        if (request == _request && !emit.isDone)
          emit(FindCompanyState(companies: companies));
      } catch (error) {
        if (request == _request && !emit.isDone)
          emit(
            FindCompanyState(
              error: error.toString().replaceFirst('Exception: ', ''),
            ),
          );
      }
    });
  }
}
