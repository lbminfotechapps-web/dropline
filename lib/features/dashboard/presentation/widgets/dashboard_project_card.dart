import 'package:dropline/core/theme/appcolors.dart';

import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:dropline/features/dashboard/presentation/widgets/dashboard_clock_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ======================================================
// PROJECT SELECTOR ON DASHBOARD
// ======================================================

class DashboardProjectCard extends StatefulWidget {
  final ProjectEntity? selectedProject;
  final ValueChanged<ProjectEntity>? onProjectSelected;
  final VoidCallback? onRemoveProject;
  final String workspaceLabel;

  const DashboardProjectCard({
    super.key,
    this.selectedProject,
    this.onProjectSelected,
    this.onRemoveProject,
    this.workspaceLabel = 'Personal · Private',
  });

  @override
  State<DashboardProjectCard> createState() => _DashboardProjectCardState();
}

class _DashboardProjectCardState extends State<DashboardProjectCard> {
  bool _isOpening = false;

  Future<void> _openProjectPicker() async {
    if (_isOpening) return;

    setState(() => _isOpening = true);

    try {
      final bloc = context.read<DashboardBloc>();

      if (bloc.state.dashboardStatus == DashboardStatus.initial) {
        bloc.add(const GetProjectList());
      }

      final selectedProject = await showModalBottomSheet<ProjectEntity>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.sheetBackground,
        barrierColor: AppColors.black.withValues(alpha: 0.65),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) {
          return BlocProvider.value(
            value: bloc,
            child: _ProjectBottomSheet(workspaceLabel: widget.workspaceLabel),
          );
        },
      );

      if (!mounted) return;

      if (selectedProject != null) {
        widget.onProjectSelected?.call(selectedProject);
      }
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.selectedProject;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROJECT',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 7),

        Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: _openProjectPicker,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      project?.projectName ?? 'Select project',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: project == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  if (project != null)
                    IconButton(
                      tooltip: 'Remove project',
                      onPressed: widget.onRemoveProject,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 19,
                      ),
                    ),

                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================
// PROJECT BOTTOM SHEET
// ======================================================

class _ProjectBottomSheet extends StatefulWidget {
  final String workspaceLabel;

  const _ProjectBottomSheet({required this.workspaceLabel});

  @override
  State<_ProjectBottomSheet> createState() => _ProjectBottomSheetState();
}

class _ProjectBottomSheetState extends State<_ProjectBottomSheet> {
  final TextEditingController _projectController = TextEditingController();

  final FocusNode _projectFocusNode = FocusNode();

  bool _showAddProject = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _projectController.dispose();
    _projectFocusNode.dispose();
    super.dispose();
  }

  void _openAddProject() {
    setState(() {
      _showAddProject = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _projectFocusNode.requestFocus();
      }
    });
  }

  void _closeAddProject() {
    _projectFocusNode.unfocus();
    _projectController.clear();

    setState(() {
      _showAddProject = false;
    });
  }

  void _selectProject(ProjectEntity project) {
    _projectFocusNode.unfocus();
    Navigator.of(context).pop(project);
  }

  // ======================================================
  // ADD MANUAL PROJECT (EXISTING FUNCTIONALITY)
  // ======================================================

  void _addManualProject() {
    final projectName = _projectController.text.trim();

    if (projectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter project name')),
      );
      return;
    }

    final projects = context.read<DashboardBloc>().state.projectList;

    ProjectEntity? existingProject;

    for (final project in projects) {
      if (project.projectName.trim().toLowerCase() ==
          projectName.toLowerCase()) {
        existingProject = project;
        break;
      }
    }

    // Preserve the original project ID for an existing project.
    // New manual projects use the same empty ID as your old code.
    final selected =
        existingProject ??
        ProjectEntity(projectId: '', projectName: projectName);

    _selectProject(selected);
  }

  List<ProjectEntity> _filterProjects(List<ProjectEntity> projects) {
    if (_searchQuery.isEmpty) return projects;

    return projects.where((project) {
      return project.projectName.toLowerCase().contains(_searchQuery) ||
          project.projectId.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SizedBox(
        height: (screenHeight * 0.75 - keyboardInset).clamp(
          0.0,
          double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // DRAG HANDLE
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.sheetHandle,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // TITLE + ADD BUTTON
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select project',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.workspaceLabel,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _showAddProject
                          ? _closeAddProject
                          : _openAddProject,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          _showAddProject
                              ? Icons.close_rounded
                              : Icons.add_rounded,
                          color: AppColors.primaryText,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ADD PROJECT FIELD
              if (_showAddProject) ...[
                _buildAddProjectField(),
                const SizedBox(height: 15),
              ],

              // SEARCH EXISTING PROJECTS
              if (!_showAddProject) ...[
                _buildSearchField(),
                const SizedBox(height: 16),
              ],

              // PROJECT LIST FROM API
              Flexible(child: _buildProjectList()),

              const SizedBox(height: 22),

              // CANCEL BUTTON
              SizedBox(
                height: 53,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // SEARCH TEXTFIELD
  // ======================================================

  Widget _buildSearchField() {
    return SizedBox(
      height: 47,
      child: TextField(
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        cursorColor: AppColors.primary,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search project',
          hintStyle: const TextStyle(color: AppColors.hintText),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.iconColor,
            size: 20,
          ),
          filled: true,
          fillColor: AppColors.inputBackground,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  // ======================================================
  // MANUAL PROJECT INPUT
  // ======================================================

  Widget _buildAddProjectField() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 49,
            child: TextField(
              controller: _projectController,
              focusNode: _projectFocusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addManualProject(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Enter project name',
                hintStyle: const TextStyle(color: AppColors.hintText),
                filled: true,
                fillColor: AppColors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        SizedBox(
          height: 49,
          child: ElevatedButton(
            onPressed: _addManualProject,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ======================================================
  // PROJECT LIST USING EXISTING DASHBOARD BLOC
  // ======================================================

  Widget _buildProjectList() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state.dashboardStatus == DashboardStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state.dashboardStatus == DashboardStatus.failure) {
          return _buildErrorState(state.errorMessage);
        }

        if (state.dashboardStatus == DashboardStatus.initial) {
          return const Center(
            child: Text(
              'Loading projects...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final projects = _filterProjects(state.projectList);

        if (projects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 25),
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'No matching projects found'
                    : 'No projects available',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 11),
          itemBuilder: (context, index) {
            final project = projects[index];

            return _buildProjectItem(project);
          },
        );
      },
    );
  }

  // ======================================================
  // SINGLE PROJECT ITEM
  // ======================================================

  Widget _buildProjectItem(ProjectEntity project) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => _selectProject(project),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(minHeight: 65),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  project.projectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              const Text(
                'Select',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // ERROR STATE
  // ======================================================

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            message.isNotEmpty ? message : 'Unable to load projects',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              context.read<DashboardBloc>().add(const GetProjectList());
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
