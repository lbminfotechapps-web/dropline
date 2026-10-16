
import 'package:dropline/features/event/domain/entities/event_draft_scope.dart';
import 'package:dropline/features/event/domain/repositories/location_selection_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/location_node.dart';
import '../../domain/entities/selected_location.dart';
import '../../domain/repositories/location_repository.dart';

class SelectLocationState {
  final List<LocationNode> mainAreas;
  final List<LocationNode> subAreas;
  final List<LocationNode> locations;
  final List<LocationNode> specificLocations;

  final LocationNode? selectedMainArea;
  final LocationNode? selectedSubArea;
  final LocationNode? selectedLocation;
  final LocationNode? selectedSpecificLocation;

  final bool isLoading;
  final bool isLoadingChildren;
  final String? error;

  const SelectLocationState({
    this.mainAreas = const [],
    this.subAreas = const [],
    this.locations = const [],
    this.specificLocations = const [],
    this.selectedMainArea,
    this.selectedSubArea,
    this.selectedLocation,
    this.selectedSpecificLocation,
    this.isLoading = false,
    this.isLoadingChildren = false,
    this.error,
  });

  bool get canUseLocation =>
      selectedMainArea != null &&
      selectedSubArea != null &&
      selectedLocation != null &&
      selectedSpecificLocation != null &&
      !isLoading &&
      !isLoadingChildren;

  SelectedLocation? get selectedResult {
    if (!canUseLocation) return null;

    return SelectedLocation(
      mainArea: selectedMainArea!,
      subArea: selectedSubArea!,
      location: selectedLocation!,
      specificLocation: selectedSpecificLocation!,
    );
  }

  SelectLocationState copyWith({
    List<LocationNode>? mainAreas,
    List<LocationNode>? subAreas,
    List<LocationNode>? locations,
    List<LocationNode>? specificLocations,
    LocationNode? selectedMainArea,
    LocationNode? selectedSubArea,
    LocationNode? selectedLocation,
    LocationNode? selectedSpecificLocation,
    bool resetMainArea = false,
    bool resetSubArea = false,
    bool resetLocation = false,
    bool resetSpecificLocation = false,
    bool? isLoading,
    bool? isLoadingChildren,
    String? error,
    bool clearError = false,
  }) {
    return SelectLocationState(
      mainAreas: mainAreas ?? this.mainAreas,
      subAreas: subAreas ?? this.subAreas,
      locations: locations ?? this.locations,
      specificLocations:
          specificLocations ?? this.specificLocations,
      selectedMainArea: resetMainArea
          ? null
          : selectedMainArea ?? this.selectedMainArea,
      selectedSubArea: resetSubArea
          ? null
          : selectedSubArea ?? this.selectedSubArea,
      selectedLocation: resetLocation
          ? null
          : selectedLocation ?? this.selectedLocation,
      selectedSpecificLocation: resetSpecificLocation
          ? null
          : selectedSpecificLocation ??
              this.selectedSpecificLocation,
      isLoading: isLoading ?? this.isLoading,
      isLoadingChildren:
          isLoadingChildren ?? this.isLoadingChildren,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class SelectLocationCubit extends Cubit<SelectLocationState> {
  final LocationRepository repository;
    final LocationSelectionRepository selectionRepository;
  final EventDraftScope scope;

  SelectLocationCubit({
    required this.repository,
      required this.selectionRepository,
    required this.scope,
  }) : super(const SelectLocationState());

  // Invalidates outdated asynchronous requests.
  int _requestVersion = 0;

 Future<void> loadMainAreas() async {
  final request = ++_requestVersion;

  emit(const SelectLocationState(
    isLoading: true,
  ));

  try {
    final areas = await repository.getChildren(
      level: LocationLevel.mainArea,
    );

    if (isClosed || request != _requestVersion) return;

    emit(SelectLocationState(
      mainAreas: areas,
    ));

    await restoreSavedSelection();
  } catch (e) {
    if (isClosed || request != _requestVersion) return;

    emit(SelectLocationState(
      error: e.toString(),
    ));
  }
}

Future<void> restoreSavedSelection() async {
  final saved = await selectionRepository.getSelection(scope);

  if (isClosed || saved == null) return;

  bool containsId(List<LocationNode> nodes, String id) {
    return nodes.any((node) => node.id == id);
  }

  if (!containsId(state.mainAreas, saved.mainArea.id)) {
    return;
  }

  await selectMainArea(saved.mainArea);
  if (isClosed || state.error != null) return;

  if (!containsId(state.subAreas, saved.subArea.id)) {
    return;
  }

  await selectSubArea(saved.subArea);
  if (isClosed || state.error != null) return;

  if (!containsId(state.locations, saved.location.id)) {
    return;
  }

  await selectLocation(saved.location);
  if (isClosed || state.error != null) return;

  if (!containsId(
    state.specificLocations,
    saved.specificLocation.id,
  )) {
    return;
  }

  selectSpecificLocation(saved.specificLocation);
}


Future<bool> saveCurrentSelection() async {
  final selected = state.selectedResult;

  if (selected == null) return false;

  try {
    await selectionRepository.saveSelection(
      scope,
      selected,
    );

    return true;
  } catch (e) {
    if (!isClosed) {
      emit(state.copyWith(
        error: 'Unable to save selected location: $e',
      ));
    }

    return false;
  }
}

  // Call after returning from Edit Areas.
  Future<void> refreshAfterEditing() async {
    await loadMainAreas();
  }

  Future<void> selectMainArea(LocationNode area) async {
    final request = ++_requestVersion;

    emit(state.copyWith(
      selectedMainArea: area,
      resetSubArea: true,
      resetLocation: true,
      resetSpecificLocation: true,
      subAreas: [],
      locations: [],
      specificLocations: [],
      isLoadingChildren: true,
      clearError: true,
    ));

    try {
      final subAreas = await repository.getChildren(
        level: LocationLevel.subArea,
        parentId: area.id,
      );

      if (isClosed || request != _requestVersion) return;

      emit(state.copyWith(
        subAreas: subAreas,
        isLoadingChildren: false,
      ));
    } catch (e) {
      if (isClosed || request != _requestVersion) return;

      emit(state.copyWith(
        isLoadingChildren: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> selectSubArea(LocationNode subArea) async {
    final request = ++_requestVersion;

    emit(state.copyWith(
      selectedSubArea: subArea,
      resetLocation: true,
      resetSpecificLocation: true,
      locations: [],
      specificLocations: [],
      isLoadingChildren: true,
      clearError: true,
    ));

    try {
      final locations = await repository.getChildren(
        level: LocationLevel.location,
        parentId: subArea.id,
      );

      if (isClosed || request != _requestVersion) return;

      emit(state.copyWith(
        locations: locations,
        isLoadingChildren: false,
      ));
    } catch (e) {
      if (isClosed || request != _requestVersion) return;

      emit(state.copyWith(
        isLoadingChildren: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> selectLocation(LocationNode location) async {
    final request = ++_requestVersion;

    emit(state.copyWith(
      selectedLocation: location,
      resetSpecificLocation: true,
      specificLocations: [],
      isLoadingChildren: true,
      clearError: true,
    ));

    try {
      final specificLocations =
          await repository.getChildren(
        level: LocationLevel.specificLocation,
        parentId: location.id,
      );

      if (isClosed || request != _requestVersion) return;

      emit(state.copyWith(
        specificLocations: specificLocations,
        isLoadingChildren: false,
      ));
    } catch (e) {
      if (isClosed || request != _requestVersion) return;

      emit(state.copyWith(
        isLoadingChildren: false,
        error: e.toString(),
      ));
    }
  }

  void selectSpecificLocation(LocationNode specificLocation) {
    ++_requestVersion;

    emit(state.copyWith(
      selectedSpecificLocation: specificLocation,
      isLoadingChildren: false,
      clearError: true,
    ));
  }
}
