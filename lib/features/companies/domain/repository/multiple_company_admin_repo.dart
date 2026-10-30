import '../entities/multiple_company_admin_entity.dart';

abstract class MultipleCompanyAdminRepo {
  Future<MultipleCompanyAdminResult> submit(
    MultipleCompanyAdminRequest request,
  );
}
