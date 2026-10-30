import '../entities/company_admin_entity.dart';

abstract class CompanyAdminRepo {
  Future<List<CompanyAdminEntity>> getPendingInvitations({
    required String loginUserId,
    required String projectId,
  });
  Future<CompanyAdminEntity> updateInvitation({
    required String loginUserId,
    required String adminOwnerId,
  });
  Future<CompanyAdminEntity> submit(CompanyAdminRequest request);
}
