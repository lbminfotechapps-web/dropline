import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:dropline/features/event/domain/entities/location_flow_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';

import '../../domain/entities/location_node.dart';
import '../cubit/main_area_cubit.dart';
import '../widgets/location_area_tile.dart';
import '../widgets/location_empty_state.dart';
import '../widgets/add_area_bottom_sheet.dart';

class MainAreaPage extends StatelessWidget {
  // Step 2: navigate to Sub-area page with this node.
  final ValueChanged<LocationNode>? onAreaTap;

  final LocationFlowArgs flowArgs;
  final VoidCallback? onFinishSetup;

  const MainAreaPage({
    super.key,
    this.onAreaTap,
    this.onFinishSetup,
    required this.flowArgs,
  });

  Future<void> _showAddAreaSheet(BuildContext context) async {
    final cubit = context.read<MainAreaCubit>();

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return AddAreaBottomSheet(
          title: 'Add Main Area',
          description: 'Start with a building, zone or another Main Area.',
          hintText: 'e.g. Building A',
          buttonText: 'Save Main Area',
          onSave: cubit.addArea,
          errorMessage: () => cubit.state.error,
        );
      },
    );
  }

  void _onAreaSelected(BuildContext context, LocationNode area) {
    context.push(
      AppRouter.subAreas,
      extra: flowArgs.copyWith(
        mainArea: area,
        clearSubArea: true,
        clearLocation: true,
      ),
    );
  }

 void _finishSetup(BuildContext context) {
  context.push(
    AppRouter.selectLocation,
    extra: flowArgs,
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
                child: BlocBuilder<MainAreaCubit, MainAreaState>(
                  builder: (context, state) {
                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 25, 28, 0),
                          sliver: SliverToBoxAdapter(child: _buildHeader()),
                        ),

                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 25, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'Main Areas',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w400,
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
                        else if (state.error != null && state.areas.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: TextButton(
                                onPressed: () =>
                                    context.read<MainAreaCubit>().loadAreas(),
                                child: const Text(
                                  'Unable to load areas. Tap to retry.',
                                  style: TextStyle(color: AppColors.white),
                                ),
                              ),
                            ),
                          )
                        else if (state.areas.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: LocationEmptyState(
                                  title: 'Add your first Main Area',
                                  subtitle:
                                      'For example, Building A or Zone 1.',
                                  onAdd: () => _showAddAreaSheet(context),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                            sliver: SliverList.separated(
                              itemCount: state.areas.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final area = state.areas[index];

                                return LocationAreaTile(
                                  title: area.name,
                                  subtitle: 'Tap to add sub-areas',
                                  onTap: () => _onAreaSelected(context, area),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom fixed actions
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.22),
                ),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: AppColors.white,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                'Set up areas',
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          'Create the areas your team will select.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return BlocBuilder<MainAreaCubit, MainAreaState>(
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
                  onPressed: () => _showAddAreaSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7F8F9),
                    foregroundColor: const Color(0xFF151C29),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    '+ Add Main Area',
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
                  // onPressed: state.areas.isEmpty
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
