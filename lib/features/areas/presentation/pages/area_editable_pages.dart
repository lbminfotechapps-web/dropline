import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/theme/app_text_styles.dart';

class AreaEditablePage extends StatefulWidget {
  const AreaEditablePage({
    super.key,
    this.projectName = 'Laxmi Gauri',
    this.labels = const ['Building', 'Level', 'Apartment', 'Room'],
    this.aboutAreas = '',
  });
  final String projectName;
  final List<String> labels;
  final String aboutAreas;

  @override
  State<AreaEditablePage> createState() => _AreaEditablePageState();
}

class _AreaNode {
  _AreaNode(this.name);
  String name;
  final List<_AreaNode> children = [];
}

class _AreaEditablePageState extends State<AreaEditablePage> {
  static const _bg = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _white = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);
  final List<_AreaNode> _roots = [];
  final List<_AreaNode?> _selected = List.filled(4, null);
  late List<String> _labels;
  late String _about;
  final _addControllers = List.generate(4, (_) => TextEditingController());
  final _addErrors = List<String?>.filled(4, null);
  final _editController = TextEditingController();
  _AreaNode? _editing;
  String? _editError;

  @override
  void initState() {
    super.initState();
    const defaults = ['Building', 'Level', 'Apartment', 'Room'];
    _labels = List.generate(
      4,
      (i) => i < widget.labels.length ? widget.labels[i] : defaults[i],
    );
    _about = widget.aboutAreas;
  }

  List<_AreaNode> _options(int level) =>
      level == 0 ? _roots : _selected[level - 1]?.children ?? [];

  void _select(int level, _AreaNode node) {
    if (_selected[level] == node) return;
    setState(() {
      _editing = null;
      _setSelection(level, node);
    });
  }

  void _setSelection(int level, _AreaNode node) {
    _selected[level] = node;
    for (var i = level + 1; i < _selected.length; i++) {
      _selected[i] = null;
      _addControllers[i].clear();
      _addErrors[i] = null;
    }
  }

  @override
  void dispose() {
    for (final controller in _addControllers) {
      controller.dispose();
    }
    _editController.dispose();
    super.dispose();
  }

  void _add(int level) {
    final controller = _addControllers[level];
    final names = controller.text
        .split('\n')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      setState(() => _addErrors[level] = 'Enter at least one name');
      return;
    }

    final options = _options(level);
    final seen = options.map((node) => node.name.toLowerCase()).toSet();
    for (final name in names) {
      if (!seen.add(name.toLowerCase())) {
        setState(() => _addErrors[level] = 'Duplicate name: $name');
        return;
      }
    }

    final nodes = names.map(_AreaNode.new).toList();
    FocusScope.of(context).unfocus();
    setState(() {
      options.addAll(nodes);
      controller.clear();
      _addErrors[level] = null;
      _editing = null;
      _setSelection(level, nodes.first);
    });
  }

  void _startEditing(_AreaNode node) {
    _editController.value = TextEditingValue(
      text: node.name,
      selection: TextSelection(baseOffset: 0, extentOffset: node.name.length),
    );
    setState(() {
      _editing = node;
      _editError = null;
    });
  }

  bool _saveEdit(int level, _AreaNode node) {
    final name = _editController.text.trim();
    if (name.isEmpty) {
      setState(() => _editError = 'Enter a name');
      return false;
    }
    if (_options(level).any(
      (other) =>
          other != node && other.name.toLowerCase() == name.toLowerCase(),
    )) {
      setState(() => _editError = 'Duplicate name: $name');
      return false;
    }
    setState(() {
      node.name = name;
      _editing = null;
    });
    return true;
  }

  void _moveArea(List<_AreaNode> options, int fromIndex, int toIndex) {
    setState(() => options.insert(toIndex, options.removeAt(fromIndex)));
  }

  InputDecoration _nameDecoration(
    double s,
    String hint,
    String? error, {
    bool compact = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8 * s),
      borderSide: const BorderSide(color: _border),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted),
      errorText: error,
      errorMaxLines: 3,
      filled: true,
      fillColor: _bg,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 8 * s,
        vertical: (compact ? 5 : 8) * s,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: _lime),
      ),
    );
  }

  Widget _areaSection(int level, double s) {
    final label = _labels[level];
    final options = _options(level);
    final enabled = level == 0 || _selected[level - 1] != null;
    final style = AppTextStyles.bodySmall.copyWith(
      fontSize: 10 * s,
      color: _white,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8 * s),
    );
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: _white,
      side: const BorderSide(color: _border),
      shape: buttonShape,
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: style),
              SizedBox(height: 4 * s),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addControllers[level],
                      enabled: enabled,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.words,
                      style: style,
                      decoration: _nameDecoration(
                        s,
                        enabled
                            ? 'New ${label.toLowerCase()}'
                            : 'Choose ${_labels[level - 1].toLowerCase()} first',
                        _addErrors[level],
                        compact: true,
                      ),
                      onChanged: (_) {
                        if (_addErrors[level] != null) {
                          setState(() => _addErrors[level] = null);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 6 * s),
                  FilledButton.icon(
                    onPressed: enabled ? () => _add(level) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _lime,
                      foregroundColor: _bg,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: buttonShape,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (options.isNotEmpty)
          SliverReorderableList(
            proxyDecorator: (child, index, animation) =>
                Material(type: MaterialType.transparency, child: child),
            itemCount: options.length,
            onReorderItem: (oldIndex, newIndex) =>
                _moveArea(options, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final node = options[index];
              return Padding(
                key: ObjectKey(node),
                padding: EdgeInsets.only(top: 5 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      color: _surface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * s),
                        side: BorderSide(
                          color: _selected[level] == node ? _lime : _border,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsetsDirectional.only(
                          start: 10 * s,
                          end: 5 * s,
                        ),
                        selected: _selected[level] == node,
                        selectedColor: _lime,
                        textColor: _white,
                        dense: true,
                        leading: options.length > 1
                            ? ReorderableDelayedDragStartListener(
                                index: index,
                                child: PopupMenuButton<int>(
                                  tooltip: '',
                                  icon: const Icon(
                                    Icons.drag_indicator,
                                    color: _muted,
                                  ),
                                  onSelected: (target) =>
                                      _moveArea(options, index, target),
                                  itemBuilder: (context) => [
                                    if (index > 0)
                                      PopupMenuItem(
                                        value: index - 1,
                                        child: const Text('Move up'),
                                      ),
                                    if (index < options.length - 1)
                                      PopupMenuItem(
                                        value: index + 1,
                                        child: const Text('Move down'),
                                      ),
                                  ],
                                ),
                              )
                            : null,
                        title: Text(node.name),
                        onTap: () => _select(level, node),
                        trailing: OutlinedButton(
                          onPressed: () => _startEditing(node),
                          style: buttonStyle,
                          child: const Text('Edit'),
                        ),
                      ),
                    ),
                    if (_editing == node)
                      Padding(
                        padding: EdgeInsets.only(top: 5 * s),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Edit ${label.toLowerCase()}', style: style),
                            SizedBox(height: 4 * s),
                            TextField(
                              controller: _editController,
                              autofocus: true,
                              textCapitalization: TextCapitalization.words,
                              style: style,
                              decoration: _nameDecoration(s, label, _editError),
                              onChanged: (_) {
                                if (_editError != null) {
                                  setState(() => _editError = null);
                                }
                              },
                              onSubmitted: (_) => _saveEdit(level, node),
                            ),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 6 * s,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _editing = null),
                                  child: const Text('Cancel'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _saveEdit(level, node),
                                  style: buttonStyle,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _editLabels() async {
    final result = await context.push<Map<String, dynamic>>(
      Uri(
        path: AppRouter.areaLabels,
        queryParameters: {'projectName': widget.projectName, 'edit': 'true'},
      ).toString(),
      extra: {'labels': _labels, 'aboutAreas': _about},
    );
    if (!mounted || result == null) return;
    setState(() {
      _labels = List<String>.from(result['labels'] as List);
      _about = result['aboutAreas'] as String;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final s = (constraints.maxWidth / 262).clamp(1.0, 1.6);
          TextStyle text(
            double size, {
            Color color = _muted,
            bool bold = false,
          }) => AppTextStyles.bodySmall.copyWith(
            fontSize: size * s,
            color: color,
            height: 1.3,
            fontWeight: bold ? FontWeight.w500 : FontWeight.w500,
          );
          final selectedNames = _selected
              .whereType<_AreaNode>()
              .map((node) => node.name)
              .toList();
          final path = selectedNames.isEmpty
              ? widget.projectName
              : selectedNames.join(' › ');
          return Padding(
            padding: EdgeInsets.fromLTRB(13 * s, 13 * s, 13 * s, 7 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 27 * s,
                      height: 28 * s,
                      child: OutlinedButton(
                        onPressed: () {
                          if (context.canPop()) context.pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: _muted,
                          backgroundColor: _surface,
                          side: const BorderSide(color: _border, width: .7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8 * s),
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          size: 16 * s,
                          semanticLabel: 'Back',
                        ),
                      ),
                    ),
                    SizedBox(width: 9 * s),
                    Text('Areas', style: text(15, bold: true, color: _white)),
                  ],
                ),

                Text(widget.projectName, style: text(8)),
                SizedBox(height: 14 * s),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: EdgeInsets.all(9 * s),
                              decoration: BoxDecoration(
                                color: _surface.withValues(alpha: .5),
                                borderRadius: BorderRadius.circular(8 * s),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected area',
                                    style: text(8, bold: true),
                                  ),
                                  SizedBox(height: 5 * s),
                                  Text(
                                    path,
                                    style: text(10, bold: true, color: _white),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10 * s),
                            Text(
                              'Tap an area to show its entries. Hold and drag a handle, or tap it for move options.',
                              style: text(9),
                            ),
                            SizedBox(height: 8 * s),
                          ],
                        ),
                      ),
                      for (var i = 0; i < _labels.length; i++) ...[
                        _areaSection(i, s),
                        SliverToBoxAdapter(child: SizedBox(height: 10 * s)),
                      ],
                      SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                    ],
                  ),
                ),
                SizedBox(height: 12 * s),
                FilledButton(
                  onPressed: () {
                    final node = _editing;
                    if (node != null) {
                      final level = _labels.asMap().keys.firstWhere(
                        (level) => _options(level).contains(node),
                      );
                      if (!_saveEdit(level, node)) return;
                    }
                    FocusScope.of(context).unfocus();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: _bg,
                    minimumSize: Size.fromHeight(34 * s),
                    padding: EdgeInsets.symmetric(vertical: 10 * s),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9 * s),
                    ),
                    textStyle: text(10, color: _bg, bold: true),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
