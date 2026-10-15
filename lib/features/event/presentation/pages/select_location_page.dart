import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

import '../../../../core/theme/app_text_styles.dart';

import '../../domain/entities/selected_location.dart';
import '../cubit/select_location_cubit.dart';
import '../widgets/location_selection_dropdown.dart';

class SelectLocationPage extends StatelessWidget {
  final ValueChanged<SelectedLocation>? onUseLocation;

  const SelectLocationPage({super.key, this.onUseLocation});

  // ==========================================
  // EDIT AREAS
  // ==========================================

  Future<void> _editAreas(BuildContext context) async {
    // Keep this page underneath the setup screen.
    await context.push(AppRouter.mainAreas);

    if (!context.mounted) return;

    // Reload the shared repository after editing.
    await context.read<SelectLocationCubit>().refreshAfterEditing();
  }

  // ==========================================
  // USE LOCATION
  // ==========================================

  void _useLocation(BuildContext context) {
    final selected = context.read<SelectLocationCubit>().state.selectedResult;

    if (selected == null) return;

    debugPrint('Selected location: ${selected.toJson()}');

    // Optional callback to the parent workflow.
    if (onUseLocation != null) {
      onUseLocation!(selected);
      return;
    }

    // For now return the selected result to the
    // screen which opened SelectLocationPage.
    if (context.canPop()) {
      context.pop(selected);
      return;
    }

    // If this screen was opened as the root route,
    // configure onUseLocation to handle navigation.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location selected. Connect the next screen.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<SelectLocationCubit, SelectLocationState>(
                  builder: (context, state) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(context),

                          const SizedBox(height: 22),

                          Text(
                            'Select where you are working '
                            'from your saved setup.',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 32),

                          if (state.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                ),
                              ),
                            )
                          else ...[
                            // Main Area
                            LocationSelectionDropdown(
                              step: 1,
                              title: 'Main Area',
                              hintText: 'Select Main Area',
                              items: state.mainAreas,
                              selectedItem: state.selectedMainArea,
                              onChanged: (area) {
                                if (area != null) {
                                  context
                                      .read<SelectLocationCubit>()
                                      .selectMainArea(area);
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // Sub-area
                            LocationSelectionDropdown(
                              step: 2,
                              title: 'Sub-area',
                              hintText: state.selectedMainArea == null
                                  ? 'Select Main Area first'
                                  : 'Select Sub-area',
                              items: state.subAreas,
                              selectedItem: state.selectedSubArea,
                              enabled:
                                  state.selectedMainArea != null &&
                                  !state.isLoadingChildren,
                              onChanged: (subArea) {
                                if (subArea != null) {
                                  context
                                      .read<SelectLocationCubit>()
                                      .selectSubArea(subArea);
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // Location
                            LocationSelectionDropdown(
                              step: 3,
                              title: 'Location',
                              hintText: state.selectedSubArea == null
                                  ? 'Select Sub-area first'
                                  : 'Select Location',
                              items: state.locations,
                              selectedItem: state.selectedLocation,
                              enabled:
                                  state.selectedSubArea != null &&
                                  !state.isLoadingChildren,
                              onChanged: (location) {
                                if (location != null) {
                                  context
                                      .read<SelectLocationCubit>()
                                      .selectLocation(location);
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // Specific Location
                            LocationSelectionDropdown(
                              step: 4,
                              title: 'Specific Location',
                              hintText: state.selectedLocation == null
                                  ? 'Select Location first'
                                  : 'Select Specific Location',
                              items: state.specificLocations,
                              selectedItem: state.selectedSpecificLocation,
                              enabled:
                                  state.selectedLocation != null &&
                                  !state.isLoadingChildren,
                              onChanged: (specificLocation) {
                                if (specificLocation != null) {
                                  context
                                      .read<SelectLocationCubit>()
                                      .selectSpecificLocation(specificLocation);
                                }
                              },
                            ),

                            if (state.isLoadingChildren) ...[
                              const SizedBox(height: 20),
                              const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                ),
                              ),
                            ],

                            if (state.error != null) ...[
                              const SizedBox(height: 18),
                              Text(
                                state.error!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context
                                    .read<SelectLocationCubit>()
                                    .loadMainAreas(),
                                child: const Text('Reload areas'),
                              ),
                            ],

                            if (state.mainAreas.isEmpty && state.error == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 22),
                                child: Text(
                                  'No Main Areas found. '
                                  'Tap Edit Areas to create one.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              _buildBottomButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Select Location',
            style: AppTextStyles.headingLarge.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(width: 10),

        OutlinedButton.icon(
          onPressed: () => _editAreas(context),
          icon: const Icon(Icons.edit_outlined, size: 17),
          label: const Text('Edit Areas'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            side: BorderSide(color: AppColors.white.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // USE LOCATION BUTTON
  // ==========================================

  Widget _buildBottomButton(BuildContext context) {
    return BlocBuilder<SelectLocationCubit, SelectLocationState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(26, 12, 26, 20),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: state.canUseLocation
                  ? () => _useLocation(context)
                  : null,
              icon: const Icon(Icons.arrow_forward_rounded, size: 22),
              label: Text(
                'Use Location',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: const Color(0xFF151C29),
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7F8F9),
                foregroundColor: const Color(0xFF151C29),
                disabledBackgroundColor: const Color(0xFF8290A1),
                disabledForegroundColor: const Color(0xFFCAD1DA),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
