import 'package:dropline/core/theme/appcolors.dart';

import 'package:dropline/features/dashboard/domain/entity/project_entity.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:dropline/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:dropline/features/newproject/presentation/pages/new_project.dart';
import 'package:flutter/material.dart';
import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ======================================================
// PROJECT SELECTOR ON DASHBOARD
// ======================================================

class DashboardProjectCard extends StatefulWidget {
  final ProjectEntity? selectedProject;
  final ValueChanged<ProjectEntity>? onProjectSelected;
  final VoidCallback? onRemoveProject;
  final bool showError;

  const DashboardProjectCard({
    super.key,
    this.selectedProject,
    this.onProjectSelected,
    this.onRemoveProject,
    this.showError = false,
  });

  @override
  State<DashboardProjectCard> createState() => _DashboardProjectCardState();
}

class _DashboardProjectCardState extends State<DashboardProjectCard> {
  bool _isOpening = false;
  final List<ProjectEntity> _manualProjects = [];

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
            child: _ProjectBottomSheet(manualProjects: _manualProjects),
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
        Text(
          'Project',
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFFADC6D9),
          ),
        ),

        const SizedBox(height: 10),

        Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: _openProjectPicker,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              constraints: const BoxConstraints(minHeight: 76),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF304F64), Color(0xFF203B4F)],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: widget.showError ? Colors.redAccent : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          project?.projectName ?? 'Select project',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: project == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (project != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Workspace: ${project.typeLabel}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFFADC6D9),
                            ),
                          ),
                        ],
                      ],
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
  final List<ProjectEntity> manualProjects;

  const _ProjectBottomSheet({required this.manualProjects});

  @override
  State<_ProjectBottomSheet> createState() => _ProjectBottomSheetState();
}

class _ProjectBottomSheetState extends State<_ProjectBottomSheet> {
  final TextEditingController _projectController = TextEditingController();

  final FocusNode _projectFocusNode = FocusNode();

  bool _showAddProject = false;
  String _searchQuery = '';
  String _projectType = 'Personal';
  bool _projectValidationAttempted = false;

  bool get _projectInvalid =>
      _projectValidationAttempted && _projectController.text.trim().isEmpty;

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
      _projectValidationAttempted = false;
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
      setState(() => _projectValidationAttempted = true);
      _projectFocusNode.requestFocus();
      return;
    }

    final projects = [
      ...context.read<DashboardBloc>().state.projectList,
      ...widget.manualProjects,
    ];

    ProjectEntity? existingProject;

    for (final project in projects) {
      if (project.projectName.trim().toLowerCase() ==
              projectName.toLowerCase() &&
          project.typeLabel == _projectType) {
        existingProject = project;
        break;
      }
    }

    // Preserve the original project ID for an existing project.
    // New manual projects use the same empty ID as your old code.
    final selected =
        existingProject ??
        ProjectEntity(
          projectId: '',
          projectName: projectName,
          projectType: _projectType,
        );

    if (existingProject == null) widget.manualProjects.add(selected);

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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Personal and Business projects',
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
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _buildProjectTypeTab('Personal'),
                      const SizedBox(width: 4),
                      _buildProjectTypeTab('Business'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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

  Future<void> _selectProjectType(String type) async {
    if (type != 'Business') {
      setState(() => _projectType = type);
      return;
    }

    _projectFocusNode.unfocus();
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const NewProjectPage(showProjectTypeSelector: false),
      ),
    );
    if (!mounted || result == null) return;

    final name = result['name']?.toString().trim() ?? '';
    if (name.isEmpty) return;
    final project = ProjectEntity(
      projectId: '',
      projectName: name,
      projectType: result['category']?.toString() ?? 'Business',
    );
    widget.manualProjects.add(project);
    _selectProject(project);
  }

  Widget _buildProjectTypeTab(String type) {
    final isSelected = _projectType == type;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _selectProjectType(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : AppColors.transparent,
                ),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Enter Personal Project name',
                hintStyle: const TextStyle(color: AppColors.hintText),
                filled: true,
                fillColor: AppColors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _projectInvalid
                        ? Colors.redAccent
                        : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _projectInvalid
                        ? Colors.redAccent
                        : AppColors.primary,
                  ),
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
              style: TextStyle(fontWeight: FontWeight.w500),
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

        final projects = _filterProjects([
          ...state.projectList,
          ...widget.manualProjects,
        ]);

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
          separatorBuilder: (_, _) => const SizedBox(height: 11),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              _ProjectTypeBadge(label: project.typeLabel),
              const SizedBox(width: 12),

              const Text(
                'Select',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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

class _ProjectTypeBadge extends StatelessWidget {
  const _ProjectTypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = label == 'Business'
        ? const Color(0xFF86DCAA)
        : const Color(0xFF91C8FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
