import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_category.dart';

class ProjectEventPage extends StatefulWidget {
  const ProjectEventPage({
    super.key,
    this.projectId = '',
    this.companyId = '',
    this.projectName = 'Laxmi Gauri',
    this.companyName = 'Apex Build',
  });

  final String projectId;
  final String companyId;
  final String projectName;
  final String companyName;

  @override
  State<ProjectEventPage> createState() => _ProjectEventPageState();
}

class _ProjectEventPageState extends State<ProjectEventPage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);

  final _categories = <ProjectEventCategory>[
    const ProjectEventCategory(
      name: 'Quality',
      events: ['Workmanship issue', 'Drawing mismatch'],
    ),
    const ProjectEventCategory(name: 'Safety', events: ['Trip hazard']),
    const ProjectEventCategory(name: 'Progress', events: ['Work completed']),
  ];

  bool _loading = true;
  bool _saving = false;
  bool _loadFailed = false;

  String get _storageKey =>
      'project_event_categories_v1:${jsonEncode([widget.companyId.isEmpty ? widget.companyName : widget.companyId, widget.projectId.isEmpty ? widget.projectName : widget.projectId])}';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_storageKey);
      final categories = saved == null
          ? List<ProjectEventCategory>.of(_categories)
          : (jsonDecode(saved) as List)
                .map(
                  (value) => ProjectEventCategory(
                    name: value['name'] as String,
                    events: List<String>.from(value['events'] as List),
                  ),
                )
                .toList();
      if (!mounted) return;
      setState(() {
        _categories
          ..clear()
          ..addAll(categories);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _saveCategories(List<ProjectEventCategory> categories) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _storageKey,
        jsonEncode([
          for (final category in categories)
            {'name': category.name, 'events': category.events},
        ]),
      );
      if (!saved) throw StateError('Category save failed');
      if (!mounted) return;
      setState(
        () => _categories
          ..clear()
          ..addAll(categories),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save categories. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _newCategory() async {
    final result = await Navigator.of(context).push<ProjectEventCategory>(
      MaterialPageRoute<ProjectEventCategory>(
        builder: (_) => AddCategoryPage(
          projectName: widget.projectName,
          existingCategoryNames: _categories.map((entry) => entry.name).toList(),
        ),
      ),
    );
    if (!mounted || result == null) return;
    await _saveCategories([..._categories, result]);
  }

  Future<void> _editCategory(ProjectEventCategory category) async {
    final result = await Navigator.of(context).push<ProjectEventCategory>(
      MaterialPageRoute<ProjectEventCategory>(
        builder: (_) => AddCategoryPage(
          projectName: widget.projectName,
          initialCategory: category,
          existingCategoryNames: _categories
              .where((entry) => !identical(entry, category))
              .map((entry) => entry.name)
              .toList(),
        ),
      ),
    );
    if (!mounted || result == null) return;
    final index = _categories.indexOf(category);
    if (index < 0) return;
    final updated = [..._categories];
    updated[index] = result;
    await _saveCategories(updated);
  }

  Future<void> _deleteCategory(ProjectEventCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Delete category?', style: TextStyle(color: _text)),
        content: Text(
          'Delete "${category.name}" and its events?',
          style: const TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _saveCategories([..._categories]..remove(category));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = constraints.maxWidth / 210;
            Text label(
              String value, {
              double size = 7,
              Color color = _text,
              bool bold = false,
            }) => Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: size * s,
                fontWeight: bold ? FontWeight.w500 : FontWeight.w500,
                letterSpacing: .15 * s,
              ),
            );
            ButtonStyle outline() => OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: _surface,
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7 * s),
              ),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 7 * s, 10 * s, 9 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 16 * s).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 21 * s,
                            height: 22 * s,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              style: outline(),
                              child: Icon(
                                Icons.chevron_left,
                                color: _muted,
                                size: 13 * s,
                              ),
                            ),
                          ),
                          SizedBox(width: 7 * s),
                          Expanded(
                            child: label('Events', size: 12, bold: true),
                          ),
                        ],
                      ),
                      SizedBox(height: 10 * s),
                      label(
                        '${widget.projectName} · ${widget.companyName}',
                        size: 6.5,
                        color: _muted,
                      ),
                      SizedBox(height: 11 * s),
                      if (_loading || _saving)
                        const Center(child: CircularProgressIndicator()),
                      if (_loadFailed)
                        TextButton(
                          onPressed: _loadCategories,
                          child: const Text(
                            'Unable to load categories. Tap to retry.',
                          ),
                        ),
                      if (!_loading && !_loadFailed)
                        for (final category in _categories)
                          Padding(
                            padding: EdgeInsets.only(bottom: 5 * s),
                            child: Material(
                              color: _surface,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(color: _border),
                                borderRadius: BorderRadius.circular(7 * s),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: _saving
                                    ? null
                                    : () => _editCategory(category),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 7 * s,
                                    vertical: 6 * s,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            label(
                                              category.name,
                                              size: 8,
                                              bold: true,
                                            ),
                                            SizedBox(height: 2 * s),
                                            label(
                                              category.events.join(' · '),
                                              size: 6,
                                              color: _muted,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete ${category.name}',
                                        onPressed: _saving
                                            ? null
                                            : () => _deleteCategory(category),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                        color: Colors.redAccent,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      SizedBox(
                        height: 28 * s,
                        child: OutlinedButton(
                          onPressed: _loading || _saving || _loadFailed
                              ? null
                              : _newCategory,
                          style: outline(),
                          child: label('+ New category', bold: true),
                        ),
                      ),
                      SizedBox(height: 20 * s),
                      const Spacer(),
                      SizedBox(
                        height: 27 * s,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: _lime,
                            foregroundColor: _background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7 * s),
                            ),
                          ),
                          child: label(
                            'Back to setup',
                            color: _background,
                            bold: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
