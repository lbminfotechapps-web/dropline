import '../../domain/entities/multiple_company_admin_entity.dart';
import '../../domain/repository/multiple_company_admin_repo.dart';
import '../datasource/multiple_company_admin_datasource.dart';

class MultipleCompanyAdminRepoImpl implements MultipleCompanyAdminRepo {
  final MultipleCompanyAdminDatasource datasource;
  MultipleCompanyAdminRepoImpl(this.datasource);
  @override
  Future<MultipleCompanyAdminResult> submit(
    MultipleCompanyAdminRequest request,
  ) => datasource.submit(request);
}
