import '../entities/company_admin_entity.dart';
import '../repository/company_admin_repo.dart';

class SubmitCompanyAdminUsecase {
  final CompanyAdminRepo repository;
  SubmitCompanyAdminUsecase(this.repository);
  Future<CompanyAdminEntity> call(CompanyAdminRequest request) =>
      repository.submit(request);
}
