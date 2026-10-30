import 'package:equatable/equatable.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class FetchProjectsEvent extends ProjectEvent {
  const FetchProjectsEvent();
}
