import '../entities/sub_company_entity.dart';
import '../repository/sub_company_repo.dart';

class SubmitSubCompanyUsecase {
  final SubCompanyRepo repository;

  SubmitSubCompanyUsecase(this.repository);

  Future<SubCompanyEntity> call({
    required String loginUserId,
    required String companyId,
    required String projectId,
    required String tradeId,
    required String subCompanyName,
  }) {
    return repository.submitSubCompany(
      loginUserId: loginUserId,
      companyId: companyId,
      projectId: projectId,
      tradeId: tradeId,
      subCompanyName: subCompanyName,
    );
  }
}
