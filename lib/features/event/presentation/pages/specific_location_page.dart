import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:dropline/features/event/domain/entities/location_flow_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

import '../../../../core/theme/app_text_styles.dart';

import '../../domain/entities/location_node.dart';
import '../cubit/specific_location_cubit.dart';
import '../widgets/add_area_bottom_sheet.dart';
import '../widgets/location_area_tile.dart';
import '../widgets/location_breadcrumb.dart';
import '../widgets/location_empty_state.dart';

class SpecificLocationPage extends StatelessWidget {
  final LocationNode mainArea;
  final LocationNode subArea;
  final LocationNode location;
  final LocationFlowArgs flowArgs;
  const SpecificLocationPage({
    super.key,
    required this.mainArea,
    required this.subArea,
    required this.location,
    required this.flowArgs,
  });

  // ==========================================
  // ADD SPECIFIC LOCATION BOTTOM SHEET
  // ==========================================

  Future<void> _showAddSpecificLocationSheet(BuildContext context) async {
    final cubit = context.read<SpecificLocationCubit>();

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => AddAreaBottomSheet(
        title: 'Add Specific Location',
        description: 'Create a specific location inside ${location.name}.',
        parentName: location.name,
        hintText: 'e.g. Left, Right, Front or Back',
        buttonText: 'Save Specific Location',
        onSave: cubit.addSpecificLocation,
        errorMessage: () => cubit.state.error,
      ),
    );
  }

  // ==========================================
  // BREADCRUMB NAVIGATION
  // ==========================================
  void _goToAllAreas(BuildContext context) {
    context.push(
      AppRouter.mainAreas,
      extra: LocationFlowArgs(
        scope: flowArgs.scope,
        projectName: flowArgs.projectName,
      ),
    );
  }

  void _goToMainArea(BuildContext context) {
    context.push(
      AppRouter.subAreas,
      extra: flowArgs.copyWith(
        mainArea: mainArea,
        clearSubArea: true,
        clearLocation: true,
      ),
    );
  }

  void _goToSubArea(BuildContext context) {
    context.push(
      AppRouter.locations,
      extra: flowArgs.copyWith(
        mainArea: mainArea,
        subArea: subArea,
        clearLocation: true,
      ),
    );
  } // ==========================================
  // SPECIFIC LOCATION ITEM TAP
  // ==========================================

  void _onSpecificLocationTap(
    BuildContext context,
    LocationNode specificLocation,
  ) {
    // This is the last level of the hierarchy.
    // No additional child screen is required.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Specific Location: ${specificLocation.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _finishSetup(BuildContext context) {
    context.push(AppRouter.selectLocation, extra: flowArgs);
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
                child:
                    BlocBuilder<SpecificLocationCubit, SpecificLocationState>(
                      builder: (context, state) {
                        return CustomScrollView(
                          slivers: [
                            // ==================================
                            // HEADER
                            // ==================================
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                              sliver: SliverToBoxAdapter(
                                child: _buildHeader(context),
                              ),
                            ),

                            // ==================================
                            // BREADCRUMB
                            // ==================================
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                              sliver: SliverToBoxAdapter(
                                child: LocationBreadcrumb(
                                  items: [
                                    LocationBreadcrumbItem(
                                      title: 'All areas',
                                      onTap: () => _goToAllAreas(context),
                                    ),
                                    LocationBreadcrumbItem(
                                      title: mainArea.name,
                                      onTap: () => _goToMainArea(context),
                                    ),
                                    LocationBreadcrumbItem(
                                      title: subArea.name,
                                      onTap: () => _goToSubArea(context),
                                    ),
                                    LocationBreadcrumbItem(
                                      title: location.name,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ==================================
                            // DESCRIPTION
                            // ==================================
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Specific Locations',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      'Add specific locations inside '
                                      '${location.name}.',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ==================================
                            // LOADING
                            // ==================================
                            if (state.isLoading)
                              const SliverFillRemaining(
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                  ),
                                ),
                              )
                            // ==================================
                            // ERROR
                            // ==================================
                            else if (state.error != null &&
                                state.specificLocations.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: TextButton(
                                    onPressed: () => context
                                        .read<SpecificLocationCubit>()
                                        .loadSpecificLocations(),
                                    child: Text(
                                      'Unable to load. Tap to retry',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                ),
                              )
                            // ==================================
                            // EMPTY STATE
                            // ==================================
                            else if (state.specificLocations.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: LocationEmptyState(
                                      title: 'Add your first Specific Location',
                                      subtitle:
                                          'For example, Left, Right, '
                                          'Front or Back.',
                                      onAdd: () =>
                                          _showAddSpecificLocationSheet(
                                            context,
                                          ),
                                    ),
                                  ),
                                ),
                              )
                            // ==================================
                            // SPECIFIC LOCATION LIST
                            // ==================================
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  16,
                                  28,
                                  24,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: state.specificLocations.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = state.specificLocations[index];

                                    return LocationAreaTile(
                                      title: item.name,
                                      subtitle: 'Specific Location',
                                      onTap: () =>
                                          _onSpecificLocationTap(context, item),
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
              ),

              // ==================================
              // BOTTOM BUTTONS
              // ==================================
              _buildBottomActions(context),
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
        Material(
          color: AppColors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(17),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.20),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Text(
            'Specific Locations',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOTTOM BUTTONS
  // ==========================================

  Widget _buildBottomActions(BuildContext context) {
    return BlocBuilder<SpecificLocationCubit, SpecificLocationState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ADD SPECIFIC LOCATION
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () => _showAddSpecificLocationSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7F8F9),
                    foregroundColor: const Color(0xFF151C29),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    '+ Add Specific Location',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: const Color(0xFF151C29),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // FINISH SETUP
              SizedBox(
                width: double.infinity,
                height: 53,
                child: OutlinedButton(
                  onPressed: () => _finishSetup(context),
                  // onPressed: state.specificLocations.isEmpty
                  //     ? null
                  //     : () => _finishSetup(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    disabledForegroundColor: AppColors.textSecondary,
                    side: BorderSide(
                      color: AppColors.white.withValues(alpha: 0.28),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Finish setup',
                    style: AppTextStyles.buttonMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
