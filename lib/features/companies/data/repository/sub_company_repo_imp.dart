import '../../domain/entities/sub_company_entity.dart';
import '../../domain/repository/sub_company_repo.dart';
import '../datasource/sub_company_datasource.dart';

class SubCompanyRepoImp implements SubCompanyRepo {
  final SubCompanyDatasource datasource;

  SubCompanyRepoImp(this.datasource);

  @override
  Future<List<SubCompanyEntity>> getSubCompanies({
    required String projectId,
    String subCompanyName = '',
    String companyId = '',
  }) => datasource.getSubCompanies(
    projectId: projectId,
    subCompanyName: subCompanyName,
    companyId: companyId,
  );

  @override
  Future<SubCompanyEntity> submitSubCompany({
    required String loginUserId,
    required String companyId,
    required String projectId,
    required String tradeId,
    required String subCompanyName,
  }) {
    return datasource.submitSubCompany(
      loginUserId: loginUserId,
      companyId: companyId,
      projectId: projectId,
      tradeId: tradeId,
      subCompanyName: subCompanyName,
    );
  }
}
