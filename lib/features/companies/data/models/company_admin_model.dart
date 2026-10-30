import '../../domain/entities/company_admin_entity.dart';

class CompanyAdminModel extends CompanyAdminEntity {
  const CompanyAdminModel({
    required super.subCompanyId,
    required super.fld_subcom_admin_det_id,
    super.status,
    required super.projectId,
    required super.roleId,
    required super.name,
    required super.mobile,
    required super.roleName,
  });
  factory CompanyAdminModel.fromJson(Map<String, dynamic> json) =>
      CompanyAdminModel(
        subCompanyId: json['fld_sub_company_id']?.toString() ?? '',
        fld_subcom_admin_det_id:
            json['fld_subcom_admin_det_id']?.toString() ?? '',
        status: json['fld_status']?.toString() ?? '',
        projectId: json['fld_project_id']?.toString() ?? '',
        roleId: json['fld_role_id']?.toString() ?? '',
        name: json['fld_admin_owner_name']?.toString() ?? '',
        mobile: json['fld_mobile_no']?.toString() ?? '',
        roleName: json['fld_role_name']?.toString() ?? '',
      );
}
