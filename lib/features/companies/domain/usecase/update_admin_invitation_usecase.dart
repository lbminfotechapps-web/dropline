import '../entities/company_admin_entity.dart';
import '../repository/company_admin_repo.dart';

class UpdateAdminInvitationUsecase {
  final CompanyAdminRepo repository;
  UpdateAdminInvitationUsecase(this.repository);
  Future<CompanyAdminEntity> call({
    required String loginUserId,
    required String adminOwnerId,
  }) => repository.updateInvitation(
    loginUserId: loginUserId,
    adminOwnerId: adminOwnerId,
  );
}
