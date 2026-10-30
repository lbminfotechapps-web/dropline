class CompanyAdminPerson {
  final String name, mobile, roleId;
  final Map<String, bool> tasks;
  CompanyAdminPerson({
    required this.name,
    required this.mobile,
    required this.roleId,
    required Map<String, bool> tasks,
  }) : tasks = Map.unmodifiable(tasks);
}

class MultipleCompanyAdminRequest {
  final String loginUserId, companyId, projectId, subCompanyId;
  final List<CompanyAdminPerson> people;
  MultipleCompanyAdminRequest({
    required this.loginUserId,
    required this.companyId,
    required this.projectId,
    required this.subCompanyId,
    required List<CompanyAdminPerson> people,
  }) : people = List.unmodifiable(people);
}

class MultipleCompanyAdminResult {
  final String message;
  const MultipleCompanyAdminResult({required this.message});
}
