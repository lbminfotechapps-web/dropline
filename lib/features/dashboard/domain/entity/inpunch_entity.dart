

import 'package:equatable/equatable.dart';

class InPunchEntity extends Equatable {
  final String inpunchId;
  final String projectId;
  final String userId;
  final String date;
  final String time;
  final String status;
  final String projectName;

  const InPunchEntity({
    required this.inpunchId,
    required this.projectId,
    required this.userId,
    required this.date,
    required this.time,
    required this.status,
    required this.projectName,
  });

  @override
  List<Object?> get props => [
        inpunchId,
        projectId,
        userId,
        date,
        time,
        status,
        projectName,
      ];
}


class InPunchResponseEntity extends Equatable {
  final bool status;
  final String message;
  final List<InPunchEntity> result;

  const InPunchResponseEntity({
    required this.status,
    required this.message,
    required this.result,
  });

  @override
  List<Object?> get props => [status, message, result];
}