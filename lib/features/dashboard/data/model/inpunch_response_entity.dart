import 'package:dropline/features/dashboard/domain/entity/inpunch_entity.dart';

class InPunchModel extends InPunchEntity {
  const InPunchModel({
    required super.inpunchId,
    required super.projectId,
    required super.userId,
    required super.date,
    required super.time,
    required super.status,
    required super.projectName,
  });

  factory InPunchModel.fromJson(Map<String, dynamic> json) {
    return InPunchModel(
      inpunchId: json['fld_inpunch_id']?.toString() ?? '',
      projectId: json['fld_project_id']?.toString() ?? '',
      userId: json['fld_user_id']?.toString() ?? '',
      date: json['fld_date']?.toString() ?? '',
      time: json['fld_time']?.toString() ?? '',
      status: json['fld_status']?.toString() ?? '',
      projectName: json['fld_project_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fld_inpunch_id': inpunchId,
      'fld_project_id': projectId,
      'fld_user_id': userId,
      'fld_date': date,
      'fld_time': time,
      'fld_status': status,
      'fld_project_name': projectName,
    };
  }
}

class InPunchResponseModel extends InPunchResponseEntity {
  const InPunchResponseModel({
    required super.status,
    required super.message,
    required List<InPunchModel> result,
  }) : super(result: result);

  factory InPunchResponseModel.fromJson(Map<String, dynamic> json) {
    return InPunchResponseModel(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      result: (json['result'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                InPunchModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result.map((item) {
        return {
          'fld_inpunch_id': item.inpunchId,
          'fld_project_id': item.projectId,
          'fld_user_id': item.userId,
          'fld_date': item.date,
          'fld_time': item.time,
          'fld_status': item.status,
          'fld_project_name': item.projectName,
        };
      }).toList(),
    };
  }
}
