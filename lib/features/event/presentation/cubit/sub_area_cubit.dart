
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/location_node.dart';
import '../../domain/repositories/location_repository.dart';

class SubAreaState {
  final List<LocationNode> subAreas;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const SubAreaState({
    this.subAreas = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  SubAreaState copyWith({
    List<LocationNode>? subAreas,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return SubAreaState(
      subAreas: subAreas ?? this.subAreas,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SubAreaCubit extends Cubit<SubAreaState> {
  final LocationRepository repository;
  final String mainAreaId;

  SubAreaCubit({
    required this.repository,
    required this.mainAreaId,
  }) : super(const SubAreaState());

  Future<void> loadSubAreas() async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    try {
      final result = await repository.getChildren(
        level: LocationLevel.subArea,
        parentId: mainAreaId,
      );

      emit(state.copyWith(
        subAreas: result,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<bool> addSubArea(String name) async {
    if (state.isSaving) return false;

    emit(state.copyWith(
      isSaving: true,
      clearError: true,
    ));

    try {
      await repository.addNode(
        name: name,
        level: LocationLevel.subArea,
        parentId: mainAreaId,
      );

      final result = await repository.getChildren(
        level: LocationLevel.subArea,
        parentId: mainAreaId,
      );

      emit(state.copyWith(
        subAreas: result,
        isSaving: false,
        clearError: true,
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
