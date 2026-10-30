import '../../domain/entities/multiple_company_admin_entity.dart';

class MultipleCompanyAdminModel extends MultipleCompanyAdminResult {
  const MultipleCompanyAdminModel({required super.message});
  factory MultipleCompanyAdminModel.fromJson(Map<String, dynamic> json) {
    if (json['status'] != true) {
      throw Exception(json['message']?.toString() ?? 'Unable to invite people');
    }
    return MultipleCompanyAdminModel(
      message:
          json['message']?.toString() ?? 'Invitations created successfully',
    );
  }

  static Map<String, dynamic> personToJson(CompanyAdminPerson person) => {
    'admin_owner_name': person.name,
    'mobile_no': person.mobile,
    'role_id': int.parse(person.roleId),
    'task_define_arr': person.tasks.entries
        .map(
          (task) => {
            'task_define_id': int.parse(task.key),
            'flag': task.value ? 1 : 0,
          },
        )
        .toList(),
  };
}
