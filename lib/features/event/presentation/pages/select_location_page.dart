import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:dropline/features/event/data/services/event_submission_preview_service.dart';
import 'package:dropline/features/event/domain/entities/location_flow_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

import '../../../../core/theme/app_text_styles.dart';

import '../../domain/entities/selected_location.dart';
import '../cubit/select_location_cubit.dart';
import '../widgets/location_selection_dropdown.dart';

class SelectLocationPage extends StatefulWidget {
  final ValueChanged<SelectedLocation>? onUseLocation;
  final LocationFlowArgs flowArgs;
  const SelectLocationPage({
    super.key,
    this.onUseLocation,
    required this.flowArgs,
  });

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  bool _isSubmitting = false;
  Future<void> _editAreas(BuildContext context) async {
    await context.push(
      AppRouter.mainAreas,
      extra: LocationFlowArgs(scope: widget.flowArgs.scope,projectName: widget.flowArgs.projectName,),
    );

    if (!context.mounted) return;

    await context.read<SelectLocationCubit>().refreshAfterEditing();
  }

  Future<void> _useLocation(BuildContext context) async {
    if (_isSubmitting) return;

    final cubit = context.read<SelectLocationCubit>();

    final selected = cubit.state.selectedResult;

    if (selected == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ======================================
      // STEP 1: SAVE CURRENT SELECTION
      // ======================================

      final saved = await cubit.saveCurrentSelection();

      if (!saved) {
        throw StateError('Unable to save selected location.');
      }

      // ======================================
      // STEP 2: PRINT ALL SAVED EVENT DATA
      // STEP 3: CLEAR SESSION DATA
      // ======================================

      final payload = await sl<EventSubmissionPreviewService>().previewAndClear(
        scope: widget.flowArgs.scope,
        projectName: widget.flowArgs.projectName,
      );

      // ======================================
      // STEP 4: AFTER LOCAL CLEANUP
      // ======================================

      if (!mounted) return;

      debugPrint(
        'TOTAL SUBMITTED TIME SLOTS: '
        '${payload['total_time_slots']}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event data printed and local drafts cleared.'),
        ),
      );

      // Return to a fresh workflow.
      // This should navigate to your dashboard,
      // not reuse an AddEventPage that still holds
      // old notes and attachments in memory.
      context.go('/dashboard');
    } catch (e, stackTrace) {
      debugPrint('EVENT PREVIEW ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to complete local submission: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
  Widget _buildBottomButton(BuildContext context) {
    return BlocBuilder<SelectLocationCubit, SelectLocationState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(26, 12, 26, 20),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: state.canUseLocation && !_isSubmitting
                  ? () => _useLocation(context)
                  : null,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF151C29),
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 22),
              label: Text(
                _isSubmitting ? 'Preparing event data...' : 'Use Location',
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
