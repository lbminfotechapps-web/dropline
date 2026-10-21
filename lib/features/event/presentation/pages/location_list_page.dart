import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:dropline/features/event/domain/entities/location_flow_args.dart';
import 'package:dropline/features/event/helper/finish_location_setup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';

import '../../domain/entities/location_node.dart';
import '../cubit/location_list_cubit.dart';
import '../widgets/add_area_bottom_sheet.dart';
import '../widgets/location_area_tile.dart';
import '../widgets/location_breadcrumb.dart';
import '../widgets/location_empty_state.dart';

class LocationListPage extends StatelessWidget {
  final LocationNode mainArea;
  final LocationNode subArea;
  final LocationFlowArgs flowArgs;
  const LocationListPage({
    super.key,
    required this.mainArea,
    required this.subArea,
    required this.flowArgs,
  });

  // ==========================================
  // ADD LOCATION BOTTOM SHEET
  // ==========================================

  Future<void> _showAddLocationSheet(BuildContext context) async {
    final cubit = context.read<LocationListCubit>();

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return AddAreaBottomSheet(
          title: 'Add Location',
          description: 'Create a location inside ${subArea.name}.',
          parentName: subArea.name,
          hintText: 'e.g. Office, Hall or Meeting Room',
          buttonText: 'Save Location',
          onSave: cubit.addLocation,
          errorMessage: () => cubit.state.error,
        );
      },
    );
  }

  void _onLocationTap(BuildContext context, LocationNode location) {
    context.push(
      AppRouter.specificLocations,
      extra: flowArgs.copyWith(location: location),
    );
  }

  // void _finishSetup(BuildContext context) {
  //   context.push(AppRouter.selectLocation, extra: flowArgs);
  // }

  Future<void> _finishSetup(BuildContext context) async {
  await finishLocationSetup(
    context,
    flowArgs: flowArgs,
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
                child: BlocBuilder<LocationListCubit, LocationListState>(
                  builder: (context, state) {
                    return CustomScrollView(
                      slivers: [
                        // Header
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: _buildHeader(context),
                          ),
                        ),

                        // Breadcrumb
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: LocationBreadcrumb(
                              items: [
                                LocationBreadcrumbItem(
                                  title: 'All areas',
                                  onTap: () => context.go('/main-areas'),
                                ),
                                LocationBreadcrumbItem(
                                  title: mainArea.name,
                                  onTap: () => context.pop(),
                                ),
                                LocationBreadcrumbItem(title: subArea.name),
                              ],
                            ),
                          ),
                        ),

                        // Description
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'Add locations inside ${subArea.name}.',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),

                        // Loading
                        if (state.isLoading)
                          const SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                              ),
                            ),
                          )
                        // Error
                        else if (state.error != null && state.locations.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: TextButton(
                                onPressed: () => context
                                    .read<LocationListCubit>()
                                    .loadLocations(),
                                child: Text(
                                  'Unable to load locations. Retry',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                            ),
                          )
                        // Empty State
                        else if (state.locations.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: LocationEmptyState(
                                  title: 'Add your first Location',
                                  subtitle:
                                      'For example, Office or Meeting Room.',
                                  onAdd: () => _showAddLocationSheet(context),
                                ),
                              ),
                            ),
                          )
                        // List
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                            sliver: SliverList.separated(
                              itemCount: state.locations.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final location = state.locations[index];

                                return LocationAreaTile(
                                  title: location.name,
                                  subtitle: 'Tap to add Specific Locations',
                                  onTap: () =>
                                      _onLocationTap(context, location),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom buttons
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

        const SizedBox(width: 16),

        Expanded(
          child: Text(
            'Locations',
            style: AppTextStyles.headingLarge.copyWith(
              fontSize: 28,
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
    return BlocBuilder<LocationListCubit, LocationListState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () => _showAddLocationSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7F8F9),
                    foregroundColor: const Color(0xFF151C29),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    '+ Add Location',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: const Color(0xFF151C29),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 53,
                child: OutlinedButton(
                  onPressed: () => _finishSetup(context),
                  // onPressed: state.locations.isEmpty
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
                      fontWeight: FontWeight.w400,
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
