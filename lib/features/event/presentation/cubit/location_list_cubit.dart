
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/location_node.dart';
import '../../domain/repositories/location_repository.dart';

class LocationListState {
  final List<LocationNode> locations;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const LocationListState({
    this.locations = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  LocationListState copyWith({
    List<LocationNode>? locations,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return LocationListState(
      locations: locations ?? this.locations,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LocationListCubit extends Cubit<LocationListState> {
  final LocationRepository repository;
  final String subAreaId;

  LocationListCubit({
    required this.repository,
    required this.subAreaId,
  }) : super(const LocationListState());

  Future<void> loadLocations() async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    try {
      final locations = await repository.getChildren(
        level: LocationLevel.location,
        parentId: subAreaId,
      );

      emit(state.copyWith(
        locations: locations,
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

  Future<bool> addLocation(String name) async {
    if (state.isSaving) return false;

    emit(state.copyWith(
      isSaving: true,
      clearError: true,
    ));

    try {
      await repository.addNode(
        name: name,
        level: LocationLevel.location,
        parentId: subAreaId,
      );

      final locations = await repository.getChildren(
        level: LocationLevel.location,
        parentId: subAreaId,
      );

      emit(state.copyWith(
        locations: locations,
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
