
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/location_node.dart';
import '../../domain/repositories/location_repository.dart';

class SpecificLocationState {
  final List<LocationNode> specificLocations;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const SpecificLocationState({
    this.specificLocations = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  SpecificLocationState copyWith({
    List<LocationNode>? specificLocations,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return SpecificLocationState(
      specificLocations:
          specificLocations ?? this.specificLocations,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SpecificLocationCubit extends Cubit<SpecificLocationState> {
  final LocationRepository repository;
  final String locationId;

  SpecificLocationCubit({
    required this.repository,
    required this.locationId,
  }) : super(const SpecificLocationState());

  // ==========================================
  // LOAD SPECIFIC LOCATIONS
  // ==========================================

  Future<void> loadSpecificLocations() async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    try {
      final result = await repository.getChildren(
        level: LocationLevel.specificLocation,
        parentId: locationId,
      );

      emit(state.copyWith(
        specificLocations: result,
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

  // ==========================================
  // ADD SPECIFIC LOCATION
  // ==========================================

  Future<bool> addSpecificLocation(String name) async {
    if (state.isSaving) return false;

    emit(state.copyWith(
      isSaving: true,
      clearError: true,
    ));

    try {
      await repository.addNode(
        name: name.trim(),
        level: LocationLevel.specificLocation,
        parentId: locationId,
      );

      final result = await repository.getChildren(
        level: LocationLevel.specificLocation,
        parentId: locationId,
      );

      emit(state.copyWith(
        specificLocations: result,
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
