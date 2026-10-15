import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/location_node.dart';
import '../../domain/repositories/location_repository.dart';

class MainAreaState {
  final List<LocationNode> areas;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const MainAreaState({
    this.areas = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  MainAreaState copyWith({
    List<LocationNode>? areas,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return MainAreaState(
      areas: areas ?? this.areas,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class MainAreaCubit extends Cubit<MainAreaState> {
  final LocationRepository repository;

  MainAreaCubit(this.repository)
      : super(const MainAreaState());

  Future<void> loadAreas() async {
    emit(state.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final areas = await repository.getChildren(
        level: LocationLevel.mainArea,
      );

      emit(state.copyWith(
        areas: areas,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<bool> addArea(String name) async {
    if (state.isSaving) return false;

    emit(state.copyWith(
      isSaving: true,
      error: null,
    ));

    try {
      await repository.addNode(
        name: name,
        level: LocationLevel.mainArea,
      );

      final areas = await repository.getChildren(
        level: LocationLevel.mainArea,
      );

      emit(state.copyWith(
        areas: areas,
        isSaving: false,
        error: null,
      ));

      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        error: e.toString(),
      ));

      return false;
    }
  }
}