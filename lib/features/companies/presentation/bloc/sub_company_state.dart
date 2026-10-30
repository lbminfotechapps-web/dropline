import 'package:equatable/equatable.dart';
import '../../domain/entities/sub_company_entity.dart';

abstract class SubCompanyState extends Equatable {
  const SubCompanyState();

  @override
  List<Object?> get props => [];
}

class SubCompanyInitial extends SubCompanyState {}

class SubCompanyLoading extends SubCompanyState {}

class SubCompanySuccess extends SubCompanyState {
  final SubCompanyEntity subCompany;

  const SubCompanySuccess(this.subCompany);

  @override
  List<Object?> get props => [subCompany];
}

class SubCompanyError extends SubCompanyState {
  final String message;

  const SubCompanyError(this.message);

  @override
  List<Object?> get props => [message];
}
