import '../entities/multiple_company_admin_entity.dart';
import '../repository/multiple_company_admin_repo.dart';

class SubmitMultipleCompanyAdminUsecase {
  final MultipleCompanyAdminRepo repository;
  SubmitMultipleCompanyAdminUsecase(this.repository);
  Future<MultipleCompanyAdminResult> call(MultipleCompanyAdminRequest request) {
    if (request.loginUserId.isEmpty || request.projectId.isEmpty) {
      throw ArgumentError('Missing login or project details');
    }
    if (request.people.isEmpty) throw ArgumentError('Add at least one person');
    return repository.submit(request);
  }
}
