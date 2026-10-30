import 'package:equatable/equatable.dart';

abstract class SubCompanyEvent extends Equatable {
  const SubCompanyEvent();

  @override
  List<Object?> get props => [];
}

class SubmitSubCompanyEvent extends SubCompanyEvent {
  final String loginUserId;
  final String companyId;
  final String projectId;
  final String tradeId;
  final String subCompanyName;

  const SubmitSubCompanyEvent({
    required this.loginUserId,
    required this.companyId,
    required this.projectId,
    required this.tradeId,
    required this.subCompanyName,
  });

  @override
  List<Object?> get props => [
    loginUserId,
    companyId,
    projectId,
    tradeId,
    subCompanyName,
  ];
}
