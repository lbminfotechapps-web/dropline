class LoginResponseModel {
  final bool status;
  final String message;
  final List<LoginUserModel> result;
  final String otp;

  const LoginResponseModel({
    required this.status,
    required this.message,
    required this.result,
    required this.otp,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      status: json['status'] == true || json['status']?.toString() == '1',
      message: json['message']?.toString() ?? '',
      result: (json['result'] as List<dynamic>? ?? [])
          .map(
            (e) => LoginUserModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      otp: json['otp']?.toString() ?? '',
    );
  }
}

class LoginUserModel {
  final String userId;
  final String name;
  final String email;
  final String mobileNo;
  final String status;
  final String address;
  final String mobileInfo;
  final String fcmId;
  final String menuId;

  const LoginUserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.mobileNo,
    required this.status,
    required this.address,
    required this.mobileInfo,
    required this.fcmId,
    required this.menuId,
  });

  factory LoginUserModel.fromJson(Map<String, dynamic> json) {
    return LoginUserModel(
      userId: json['fld_user_id']?.toString() ?? '',
      name: json['fld_name']?.toString() ?? '',
      email: json['fld_email']?.toString() ?? '',
      mobileNo: json['fld_mobile_no']?.toString() ?? '',
      status: json['fld_status']?.toString() ?? '',
      address: json['fld_address']?.toString() ?? '',
      mobileInfo: json['fld_mobile_info']?.toString() ?? '',
      fcmId: json['fld_fcm_id']?.toString() ?? '',
      menuId: json['fld_menu_id']?.toString() ?? '',
    );
  }
}
