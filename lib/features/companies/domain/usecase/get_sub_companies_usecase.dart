import '../entities/sub_company_entity.dart';
import '../repository/sub_company_repo.dart';

class GetSubCompaniesUsecase {
  final SubCompanyRepo repository;
  GetSubCompaniesUsecase(this.repository);
  Future<List<SubCompanyEntity>> call({
    required String projectId,
    String subCompanyName = '',
    String companyId = '',
  }) => repository.getSubCompanies(
    projectId: projectId,
    subCompanyName: subCompanyName,
    companyId: companyId,
  );
}
