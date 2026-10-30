import '../../domain/entities/company_admin_entity.dart';
import '../../domain/repository/company_admin_repo.dart';
import '../datasource/company_admin_datasource.dart';

class CompanyAdminRepoImpl implements CompanyAdminRepo {
  final CompanyAdminDatasource datasource;
  CompanyAdminRepoImpl(this.datasource);
  @override
  Future<List<CompanyAdminEntity>> getPendingInvitations({
    required String loginUserId,
    required String projectId,
  }) => datasource.getPendingInvitations(
    loginUserId: loginUserId,
    projectId: projectId,
  );

  @override
  Future<CompanyAdminEntity> updateInvitation({
    required String loginUserId,
    required String adminOwnerId,
  }) => datasource.updateInvitation(
    loginUserId: loginUserId,
    adminOwnerId: adminOwnerId,
  );

  @override
  Future<CompanyAdminEntity> submit(CompanyAdminRequest request) =>
      datasource.submit(request);
}
