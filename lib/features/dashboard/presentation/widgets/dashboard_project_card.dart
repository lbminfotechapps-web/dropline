import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:dropline/core/theme/appcolors.dart';

import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';

class DashboardProjectCard extends StatefulWidget {
  final ProjectEntity? selectedProject;
  final ValueChanged<ProjectEntity>? onProjectSelected;
  final VoidCallback? onRemoveProject;

  const DashboardProjectCard({
    super.key,
    this.selectedProject,
    this.onProjectSelected,
    this.onRemoveProject,
  });

  @override
  State<DashboardProjectCard> createState() => _DashboardProjectCardState();
}

class _DashboardProjectCardState extends State<DashboardProjectCard> {
  bool _isOpening = false;

  Future<void> _openProjectPicker() async {
    if (_isOpening) return;
    _isOpening = true;
    final bloc = context.read<DashboardBloc>();
    if (bloc.state.dashboardStatus == DashboardStatus.initial) {
      bloc.add(const GetProjectList());
    }
    try {
      final project = await Navigator.of(context).push<ProjectEntity>(
        PageRouteBuilder<ProjectEntity>(
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) =>
              BlocProvider.value(
                value: bloc,
                child: const _ProjectPickerPage(),
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          },
        ),
      );
      if (mounted && project != null) {
        widget.onProjectSelected?.call(project);
      }
    } finally {
      _isOpening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 591;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.65)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openProjectPicker,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                constraints: BoxConstraints(minHeight: 108 * scale),
                child: Text(
                  'SELECT PROJECT',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 28 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
          ),
          if (widget.selectedProject != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: InputChip(
                label: Text(
                  widget.selectedProject!.projectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _openProjectPicker,
                onDeleted: widget.onRemoveProject,
                deleteIcon: const Icon(Icons.close_rounded),
                deleteButtonTooltipMessage: 'Remove project',
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectPickerPage extends StatefulWidget {
  const _ProjectPickerPage();

  @override
  State<_ProjectPickerPage> createState() => _ProjectPickerPageState();
}

class _ProjectPickerPageState extends State<_ProjectPickerPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  // =========================================
  // MANUAL PROJECT SELECTION
  // =========================================

  void _selectManualProject() {
    final projectName = _searchController.text.trim();

    if (projectName.isEmpty) return;

    final projects = context.read<DashboardBloc>().state.projectList;

    // If the name exactly matches an API project,
    // select its real ID instead of creating a manual entry.
    ProjectEntity? existingProject;

    for (final project in projects) {
      if (project.projectName.trim().toLowerCase() ==
          projectName.toLowerCase()) {
        existingProject = project;
        break;
      }
    }

    final selected =
        existingProject ??
        ProjectEntity(projectId: '', projectName: projectName);

    _onProjectTap(selected);
  }
  // =========================================
  // SEARCH PROJECT
  // =========================================

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  // =========================================
  // FILTER PROJECTS
  // =========================================

  List<ProjectEntity> _filterProjects(List<ProjectEntity> projects) {
    if (_searchQuery.isEmpty) {
      return projects;
    }

    return projects.where((project) {
      final name = project.projectName.toLowerCase();
      final id = project.projectId.toLowerCase();

      return name.contains(_searchQuery) || id.contains(_searchQuery);
    }).toList();
  }

  // =========================================
  // PROJECT SELECTION
  // =========================================

  void _onProjectTap(ProjectEntity project) {
    _searchFocusNode.unfocus();
    Navigator.of(context).pop(project);
  }

  // =========================================
  // CLEAR SEARCH
  // =========================================

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });

    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'SELECT PROJECT',
                        style: AppTextStyles.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close project selection',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSearchField(),
                const SizedBox(height: 18),
                Expanded(child: _buildProjectList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================
  // SEARCH FIELD
  // =========================================

  Widget _buildSearchField() {
    return _buildProjectSearchInput();
  }

  Widget _buildProjectSearchInput() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      autofocus: true,
      cursorColor: Colors.white,
      textInputAction: TextInputAction.done,
      style: AppTextStyles.inputText,

      onChanged: _onSearchChanged,

      // Submit manually entered project
      onSubmitted: (_) => _selectManualProject(),

      decoration: InputDecoration(
        hintText: 'Search existing or enter new project',
        hintStyle: AppTextStyles.inputHint,
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),

        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.iconSecondary,
        ),

        suffixIcon: _searchQuery.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear search',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton.filled(
                      tooltip: 'Add and select entered project',
                      onPressed: _selectManualProject,
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ),
                ],
              )
            : null,

        // Keep all your existing decoration
      ),
    );
  }

  // =========================================
  // PROJECT LIST USING BLOC
  // =========================================

  Widget _buildProjectList() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        // LOADING
        if (state.dashboardStatus == DashboardStatus.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // FAILURE
        if (state.dashboardStatus == DashboardStatus.failure) {
          return _buildErrorState(state.errorMessage);
        }

        // INITIAL
        if (state.dashboardStatus == DashboardStatus.initial) {
          return const SizedBox.shrink();
        }

        // SUCCESS
        final projects = _filterProjects(state.projectList);

        if (projects.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PROJECT COUNT HEADER
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AVAILABLE PROJECTS',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                Text(
                  '${projects.length} Projects',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // PROJECT LIST
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: projects.length,
                separatorBuilder: (context, index) {
                  return Divider(
                    height: 1,
                    color: AppColors.cardBorder.withValues(alpha: 0.3),
                  );
                },
                itemBuilder: (context, index) {
                  final project = projects[index];

                  return _buildProjectItem(project);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================
  // PROJECT ITEM
  // =========================================

  Widget _buildProjectItem(ProjectEntity project) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onProjectTap(project),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: AppColors.iconSecondary,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.projectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Project ID: ${project.projectId}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================
  // EMPTY PROJECT STATE
  // =========================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.folder_off_outlined,
              color: AppColors.iconSecondary,
              size: 36,
            ),

            const SizedBox(height: 10),

            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching projects found'
                  : 'No projects available',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // ERROR STATE
  // =========================================

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 30,
          ),

          const SizedBox(height: 8),

          Text(
            message.isNotEmpty ? message : 'Unable to load projects',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),

          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: () {
              context.read<DashboardBloc>().add(const GetProjectList());
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
