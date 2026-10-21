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
import '../cubit/sub_area_cubit.dart';
import '../widgets/add_area_bottom_sheet.dart';
import '../widgets/location_area_tile.dart';
import '../widgets/location_breadcrumb.dart';
import '../widgets/location_empty_state.dart';

class SubAreaPage extends StatelessWidget {
  final LocationNode mainArea;
final LocationFlowArgs flowArgs;
  const SubAreaPage({super.key, required this.mainArea, required this.flowArgs,});

  // ==========================================
  // ADD SUB AREA
  // ==========================================

  Future<void> _showAddSubAreaSheet(BuildContext context) async {
    final cubit = context.read<SubAreaCubit>();

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return AddAreaBottomSheet(
          title: 'Add Sub-area',
          description: 'Create a sub-area under ${mainArea.name}.',
          parentName: mainArea.name,
          hintText: 'e.g. Third Floor',
          buttonText: 'Save Sub-area',
          onSave: cubit.addSubArea,
          errorMessage: () => cubit.state.error,
        );
      },
    );
  }

void _onSubAreaTap(
  BuildContext context,
  LocationNode subArea,
) {
  context.push(
    AppRouter.locations,
    extra: flowArgs.copyWith(
      subArea: subArea,
      clearLocation: true,
    ),
  );
}

// void _finishSetup(BuildContext context) {
//   context.push(
//     AppRouter.selectLocation,
//     extra: flowArgs,
//   );
// }
Future<void> _finishSetup(BuildContext context) async {
  await finishLocationSetup(
    context,
    flowArgs: flowArgs,
  );
}
  // ==========================================
  // MAIN BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<SubAreaCubit, SubAreaState>(
                  builder: (context, state) {
                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: _buildHeader(context),
                          ),
                        ),

                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: LocationBreadcrumb(
                              items: [
                                LocationBreadcrumbItem(
                                  title: 'All areas',
                                  onTap: () => context.pop(),
                                ),
                                LocationBreadcrumbItem(title: mainArea.name),
                              ],
                            ),
                          ),
                        ),

                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'Add sub-areas inside ${mainArea.name}.',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),

                        if (state.isLoading)
                          const SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                              ),
                            ),
                          )
                        else if (state.error != null && state.subAreas.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: TextButton(
                                onPressed: () =>
                                    context.read<SubAreaCubit>().loadSubAreas(),
                                child: Text(
                                  'Unable to load sub-areas. Retry',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                            ),
                          )
                        else if (state.subAreas.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: LocationEmptyState(
                                  title: 'Add your first Sub-area',
                                  subtitle:
                                      'For example, Third Floor or Level 2.',
                                  onAdd: () => _showAddSubAreaSheet(context),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                            sliver: SliverList.separated(
                              itemCount: state.subAreas.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final subArea = state.subAreas[index];

                                return LocationAreaTile(
                                  title: subArea.name,
                                  subtitle: 'Tap to add Locations',
                                  onTap: () => _onSubAreaTap(context, subArea),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

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
            'Sub-areas',
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
  // BOTTOM ACTION BUTTONS
  // ==========================================

  Widget _buildBottomActions(BuildContext context) {
    return BlocBuilder<SubAreaCubit, SubAreaState>(
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
                  onPressed: () => _showAddSubAreaSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7F8F9),
                    foregroundColor: const Color(0xFF151C29),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    '+ Add Sub-area',
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
                  // onPressed: state.subAreas.isEmpty
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
