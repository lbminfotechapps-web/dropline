import '../../domain/entities/sub_company_entity.dart';

class SubCompanyModel extends SubCompanyEntity {
  const SubCompanyModel({
    required super.id,
    required super.projectId,
    required super.projectName,
    required super.projectType,
    required super.companyId,
    required super.companyName,
    required super.subCompanyName,
    required super.tradeId,
    required super.tradeName,
    required super.subCompanyNo,
  });

  factory SubCompanyModel.fromJson(Map<String, dynamic> json) {
    String read(String key) => json[key]?.toString() ?? '';

    return SubCompanyModel(
      id: read('fld_sub_company_id'),
      projectId: read('fld_project_id'),
      projectName: read('fld_project_name'),
      projectType: read('fld_project_type'),
      companyId: read('fld_company_id'),
      companyName: read('fld_company_name'),
      subCompanyName: read('fld_sub_company_name'),
      tradeId: read('fld_trade_id'),
      tradeName: read('fld_trade_name'),
      subCompanyNo: read('fld_subcompany_no'),
    );
  }
}
