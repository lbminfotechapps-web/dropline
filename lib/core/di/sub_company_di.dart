import 'package:dropline/features/companies/data/datasource/multiple_company_admin_datasource.dart';
import 'package:dropline/features/companies/data/repository/multiple_company_admin_repo_impl.dart';
import 'package:dropline/features/companies/domain/repository/multiple_company_admin_repo.dart';
import 'package:dropline/features/companies/domain/usecase/submit_multiple_company_admin_usecase.dart';
import 'package:dropline/features/companies/presentation/bloc/multiple_company_admin_cubit.dart';
import 'package:dropline/features/companies/domain/usecase/get_pending_invitations_usecase.dart';
import 'package:dropline/features/companies/presentation/bloc/pending_invitations_bloc.dart';
import 'package:dropline/features/companies/domain/usecase/update_admin_invitation_usecase.dart';
import 'package:dropline/features/companies/data/datasource/company_admin_datasource.dart';
import 'package:dropline/features/companies/data/repository/company_admin_repo_impl.dart';
import 'package:dropline/features/companies/domain/repository/company_admin_repo.dart';
import 'package:dropline/features/companies/domain/usecase/submit_company_admin_usecase.dart';
import 'package:dropline/features/companies/presentation/bloc/company_admin_bloc.dart';
import 'package:dropline/features/companies/domain/usecase/get_sub_companies_usecase.dart';
import 'package:dropline/features/companies/presentation/bloc/find_company_bloc.dart';
import 'package:dio/dio.dart';
import 'package:dropline/features/companies/data/datasource/sub_company_datasource.dart';
import 'package:dropline/features/companies/data/repository/sub_company_repo_imp.dart';
import 'package:dropline/features/companies/domain/repository/sub_company_repo.dart';
import 'package:dropline/features/companies/domain/usecase/submit_sub_company_usecase.dart';
import 'package:dropline/features/companies/presentation/bloc/sub_company_bloc.dart';
import 'package:get_it/get_it.dart';

Future<void> initSubCompanyDi(GetIt sl) async {
  sl.registerLazySingleton(() => MultipleCompanyAdminDatasource(sl<Dio>()));
  sl.registerLazySingleton<MultipleCompanyAdminRepo>(
    () => MultipleCompanyAdminRepoImpl(sl<MultipleCompanyAdminDatasource>()),
  );
  sl.registerLazySingleton(
    () => SubmitMultipleCompanyAdminUsecase(sl<MultipleCompanyAdminRepo>()),
  );
  sl.registerFactory(
    () => MultipleCompanyAdminCubit(sl<SubmitMultipleCompanyAdminUsecase>()),
  );
  sl.registerLazySingleton<GetSubCompaniesUsecase>(
    () => GetSubCompaniesUsecase(sl<SubCompanyRepo>()),
  );
  sl.registerFactory<FindCompanyBloc>(
    () => FindCompanyBloc(sl<GetSubCompaniesUsecase>()),
  );
  sl.registerLazySingleton<CompanyAdminDatasource>(
    () => CompanyAdminDatasource(sl<Dio>()),
  );
  sl.registerLazySingleton<CompanyAdminRepo>(
    () => CompanyAdminRepoImpl(sl<CompanyAdminDatasource>()),
  );
  sl.registerLazySingleton<SubmitCompanyAdminUsecase>(
    () => SubmitCompanyAdminUsecase(sl<CompanyAdminRepo>()),
  );
  sl.registerFactory<CompanyAdminBloc>(
    () => CompanyAdminBloc(sl<SubmitCompanyAdminUsecase>()),
  );
  sl.registerLazySingleton<UpdateAdminInvitationUsecase>(
    () => UpdateAdminInvitationUsecase(sl<CompanyAdminRepo>()),
  );
  sl.registerLazySingleton<GetPendingInvitationsUsecase>(
    () => GetPendingInvitationsUsecase(sl<CompanyAdminRepo>()),
  );
  sl.registerFactory<PendingInvitationsBloc>(
    () => PendingInvitationsBloc(sl<GetPendingInvitationsUsecase>()),
  );
  // Reuse your application's configured Dio instance.
  sl.registerLazySingleton<SubCompanyDatasource>(
    () => SubCompanyDatasourceImpl(sl<Dio>()),
  );

  sl.registerLazySingleton<SubCompanyRepo>(
    () => SubCompanyRepoImp(sl<SubCompanyDatasource>()),
  );

  sl.registerLazySingleton<SubmitSubCompanyUsecase>(
    () => SubmitSubCompanyUsecase(sl<SubCompanyRepo>()),
  );

  sl.registerFactory<SubCompanyBloc>(
    () => SubCompanyBloc(sl<SubmitSubCompanyUsecase>()),
  );
}
