class CompanyAdminEntity {
  final String status;
  final String subCompanyId,
      fld_subcom_admin_det_id,
      projectId,
      roleId,
      name,
      mobile,
      roleName;
  const CompanyAdminEntity({
    this.status = '',
    required this.subCompanyId,
    required this.fld_subcom_admin_det_id,
    required this.projectId,
    required this.roleId,
    required this.name,
    required this.mobile,
    required this.roleName,
  });
}

class CompanyAdminRequest {
  final String loginUserId,
      companyId,
      projectId,
      subCompanyId,
      fld_subcom_admin_det_id,
      name,
      mobile,
      roleId;
  final Map<String, bool> tasks;
  CompanyAdminRequest({
    required this.loginUserId,
    required this.companyId,
    required this.projectId,
    required this.subCompanyId,
    required this.fld_subcom_admin_det_id,
    required this.name,
    required this.mobile,
    required this.roleId,
    required Map<String, bool> tasks,
  }) : tasks = Map.unmodifiable(tasks);
}
