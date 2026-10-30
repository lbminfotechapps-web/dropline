import '../entities/sub_company_entity.dart';

abstract class SubCompanyRepo {
  Future<List<SubCompanyEntity>> getSubCompanies({
    required String projectId,
    String subCompanyName = '',
    String companyId = '',
  });
  Future<SubCompanyEntity> submitSubCompany({
    required String loginUserId,
    required String companyId,
    required String projectId,
    required String tradeId,
    required String subCompanyName,
  });
}
