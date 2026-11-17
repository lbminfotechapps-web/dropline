import '../../domain/entities/project_entity.dart';
import 'package:dropline/features/certificate/presentation/pages/dropline_card.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:dropline/features/companies/presentation/invitation_ready.dart';
import 'package:flutter/material.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:dropline/features/companies/presentation/start_work.dart';
import 'package:dropline/features/newproject/presentation/pages/new_project.dart';
import 'package:dropline/core/di/global_di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';

/// The site overview, with proportions taken from the supplied screen reference.
class MePage extends StatefulWidget {
  const MePage({
    super.key,
    this.onStartWork,
    this.sentInvitationCount = 0,
    this.receivedInvitationCount = 0,
  });

  final int sentInvitationCount;
  final int receivedInvitationCount;

  final VoidCallback? onStartWork;

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _lime = Color(0xFFB5FF65);
  String _category = 'All';
  String _query = '';
  String _language = 'English';
  bool _showSearch = false;

  late final ProjectBloc _projectBloc;

  @override
  void initState() {
    super.initState();
    _projectBloc = sl<ProjectBloc>()..add(const FetchProjectsEvent());
  }

  Future<void> _openSentInvitations() async {
    final state = _projectBloc.state;
    if (state is! ProjectLoaded || state.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Load a project to view invitations.')),
      );
      return;
    }
    final ProjectEntity? project;
    if (state.projects.length == 1) {
      project = state.projects.first;
    } else {
      project = await showModalBottomSheet<ProjectEntity>(
        context: context,
        backgroundColor: _surface,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Select project',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              for (final project in state.projects)
                ListTile(
                  title: Text(
                    project.projectName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    project.companyName,
                    style: const TextStyle(color: _muted),
                  ),
                  onTap: () => Navigator.of(context).pop(project),
                ),
            ],
          ),
        ),
      );
    }
    final selectedProject = project;
    if (!mounted || selectedProject == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => InvitationReadyPage(
          returnToMe: false,
          projectId: selectedProject.projectId,
          projectName: selectedProject.projectName,
          companyName: selectedProject.companyName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _projectBloc.close();
    super.dispose();
  }

  Text _text(String value, double size, {Color? color, bool bold = false}) =>
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: size * 0.9,
          color: color ?? const Color(0xFFF0F4FC),
          fontWeight: bold ? FontWeight.w500 : FontWeight.w500,
        ),
      );

  Widget _panel({required Widget child, VoidCallback? onTap}) => Material(
    color: _surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: _border, width: .7),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: child),
  );

  Widget _shortcut(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool chevron = false,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: _muted, size: 22),
          const SizedBox(width: 10),
          Expanded(child: _text(label, 14, bold: true)),
          if (chevron) const Icon(Icons.chevron_right, color: _muted, size: 18),
        ],
      ),
    ),
  );

  Widget _buildHeaderActions() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      PopupMenuButton<String>(
        tooltip: 'Choose language',
        initialValue: _language,
        color: _surface,
        onSelected: (value) => setState(() => _language = value),
        itemBuilder: (_) => [
          for (final language in ['English', 'Hindi'])
            CheckedPopupMenuItem<String>(
              value: language,
              checked: _language == language,
              child: _text(language, 14),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _text(
                _language == 'English' ? 'EN' : 'HI',
                15,
                color: _muted,
                bold: true,
              ),
              const SizedBox(width: 3),
              const Icon(Icons.expand_more, color: _muted, size: 20),
            ],
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        tooltip: 'Profile',
        onPressed: () => context.push(AppRouter.profile),
        style: IconButton.styleFrom(
          side: const BorderSide(color: _muted),
          foregroundColor: _muted,
        ),
        icon: const Icon(Icons.person_outline, size: 26),
      ),
    ],
  );

  void _showInvitations() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.send_outlined, color: _muted),
              title: _text('Sent invitations', 16),
              trailing: _text(
                '${widget.sentInvitationCount}',
                16,
                color: _lime,
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _openSentInvitations();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.mark_email_unread_outlined,
                color: _muted,
              ),
              title: _text('Received invitations', 16),
              trailing: _text(
                '${widget.receivedInvitationCount}',
                16,
                color: _lime,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _newProject() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<Map<String, Object?>>(
        builder: (_) => const NewProjectPage(),
      ),
    );
  }

  Widget _buildProjects() => BlocBuilder<ProjectBloc, ProjectState>(
    bloc: _projectBloc,
    builder: (context, state) {
      if (state is ProjectInitial || state is ProjectLoading) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (state is ProjectError) {
        return Column(
          children: [
            _text(state.message, 14, color: _muted),
            TextButton(
              onPressed: () => _projectBloc.add(const FetchProjectsEvent()),
              child: const Text('Retry'),
            ),
          ],
        );
      }
      if (state is! ProjectLoaded) return const SizedBox.shrink();
      final query = _query.trim().toLowerCase();
      final projects = state.projects
          .where(
            (project) =>
                (_category == 'All' ||
                    project.projectType.toLowerCase() ==
                        _category.toLowerCase()) &&
                (project.projectName.toLowerCase().contains(query) ||
                    project.companyName.toLowerCase().contains(query)),
          )
          .toList();
      if (projects.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: _text('No projects found', 14, color: _muted)),
        );
      }
      return Column(
        children: [
          for (final project in projects)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _panel(
                onTap: () => context.push(
                  Uri(
                    path: AppRouter.projectHome,
                    queryParameters: {
                      'projectName': project.projectName,
                      'projectType': project.projectType,
                      'projectId': project.projectId,
                      'companyId': project.companyId,
                      'companyName': project.companyName,
                    },
                  ).toString(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _text(project.projectName, 17, bold: true),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Expanded(
                                  child: _text(
                                    project.companyName,
                                    14,
                                    color: _muted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _border),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: _text(
                                    project.projectType,
                                    11,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.chevron_right, color: _muted, size: 24),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    appBar: CustomAppBar(
      title: 'Dropline · Site',
      height: 56,
      showBackButton: false,
      actions: [_buildHeaderActions()],
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _text('My workspace', 22, bold: true)),
                TextButton.icon(
                  onPressed: _showInvitations,
                  icon: const Icon(Icons.mail_outline, size: 23),
                  label: const Text('Invites'),
                  style: TextButton.styleFrom(
                    foregroundColor: _muted,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _panel(
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      StartWorkPage(onStartWork: widget.onStartWork),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline, size: 26, color: _muted),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _text('My work, My Money', 18, bold: true),
                          const SizedBox(height: 3),
                          _text('Shifts, rates & payments', 14, color: _muted),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: _muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _panel(
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _shortcut(
                        Icons.badge_outlined,
                        'Dropline card',
                        chevron: true,
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const DroplineCard(),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: VerticalDivider(width: 1, color: _border),
                    ),
                    Expanded(
                      child: _shortcut(
                        Icons.workspace_premium_outlined,
                        'My certificates',
                        chevron: true,
                        onTap: () => context.push(AppRouter.certificateList),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _panel(
                    child: _shortcut(Icons.article_outlined, 'My reports'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _panel(
                    child: _shortcut(Icons.account_tree_outlined, 'Handovers'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _text('My projects', 20, bold: true)),
                PopupMenuButton<String>(
                  tooltip: 'Filter projects',
                  initialValue: _category,
                  color: _surface,
                  onSelected: (value) => setState(() => _category = value),
                  itemBuilder: (_) => [
                    for (final category in ['All', 'Business', 'Personal'])
                      CheckedPopupMenuItem(
                        value: category,
                        checked: _category == category,
                        child: _text(category, 14),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        _text(_category, 14, color: _muted),
                        const Icon(Icons.expand_more, size: 18, color: _muted),
                      ],
                    ),
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Search projects',
                  onPressed: () => setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) _query = '';
                  }),
                  icon: Icon(_showSearch ? Icons.close : Icons.search),
                  style: IconButton.styleFrom(
                    foregroundColor: _muted,
                    side: const BorderSide(color: _muted),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _newProject,
                  style: FilledButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: _background,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '+ New',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            if (_showSearch) ...[
              const SizedBox(height: 10),
              TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search projects',
                  hintStyle: const TextStyle(color: _muted),
                  prefixIcon: const Icon(Icons.search, color: _muted),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildProjects(),
          ],
        ),
      ),
    ),
  );
}
