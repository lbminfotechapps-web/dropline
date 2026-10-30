import '../entities/company_admin_entity.dart';
import '../repository/company_admin_repo.dart';

class GetPendingInvitationsUsecase {
  final CompanyAdminRepo repository;
  GetPendingInvitationsUsecase(this.repository);
  Future<List<CompanyAdminEntity>> call({
    required String loginUserId,
    required String projectId,
  }) {
    if (loginUserId.isEmpty || projectId.isEmpty)
      throw Exception('Select a project to view pending invitations.');
    return repository.getPendingInvitations(
      loginUserId: loginUserId,
      projectId: projectId,
    );
  }
}
