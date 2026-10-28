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
  final String name;
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
  final _namesController = TextEditingController();
  int? _addingLevel;
  String? _addError;

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
    setState(() {
      _addingLevel = null;
      _addError = null;
      _selected[level] = node;
      for (var i = level + 1; i < 4; i++) {
        _selected[i] = null;
      }
    });
  }

  @override
  void dispose() {
    _namesController.dispose();
    super.dispose();
  }

  List<String> get _names => _namesController.text
      .split(RegExp(r'\r?\n'))
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList();

  void _add(int level) {
    setState(() {
      _addingLevel = level;
      _namesController.clear();
      _addError = null;
    });
  }

  void _cancelAdd() {
    FocusScope.of(context).unfocus();
    setState(() {
      _addingLevel = null;
      _namesController.clear();
      _addError = null;
    });
  }

  void _saveNames() {
    final level = _addingLevel;
    if (level == null) return;
    final names = _names;
    if (names.isEmpty) {
      setState(() => _addError = 'Enter at least one name');
      return;
    }
    final options = _options(level);
    final seen = options.map((node) => node.name.toLowerCase()).toSet();
    for (final name in names) {
      if (!seen.add(name.toLowerCase())) {
        setState(() => _addError = 'Duplicate name: $name');
        return;
      }
    }
    final nodes = names.map(_AreaNode.new).toList();
    options.addAll(nodes);
    _select(level, nodes.first);
    _cancelAdd();
  }

  Widget _addForm(double s) {
    final count = _names.length;
    final small = AppTextStyles.bodySmall.copyWith(
      fontSize: 8 * s,
      color: _muted,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8 * s),
    );
    return Container(
      margin: EdgeInsets.only(top: 7 * s, bottom: 4 * s),
      padding: EdgeInsets.all(8 * s),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _lime, width: .7),
        borderRadius: BorderRadius.circular(9 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Names · one per line',
            style: small.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6 * s),
          TextField(
            controller: _namesController,
            minLines: 5,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.words,
            cursorColor: _lime,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10 * s,
              color: _white,
              height: 1.5,
            ),
            onChanged: (_) => setState(() => _addError = null),
            decoration: InputDecoration(
              hintText: 'Enter names, one per line',
              hintStyle: small,
              errorText: _addError,
              errorMaxLines: 3,
              filled: true,
              fillColor: _bg,
              isDense: true,
              contentPadding: EdgeInsets.all(8 * s),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8 * s),
                borderSide: const BorderSide(color: _border, width: .7),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8 * s),
                borderSide: const BorderSide(color: _border, width: .7),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8 * s),
                borderSide: const BorderSide(color: _lime, width: .7),
              ),
            ),
          ),
          SizedBox(height: 6 * s),
          Row(
            children: [
              OutlinedButton(
                onPressed: _cancelAdd,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _muted,
                  shape: shape,
                  side: const BorderSide(color: _border, width: .7),
                  textStyle: small,
                  minimumSize: Size(62 * s, 30 * s),
                  padding: EdgeInsets.symmetric(horizontal: 10 * s),
                ),
                child: const Text('Cancel'),
              ),
              SizedBox(width: 7 * s),
              Expanded(
                child: FilledButton(
                  onPressed: _saveNames,
                  style: FilledButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: _bg,
                    shape: shape,
                    minimumSize: Size(0, 30 * s),
                    textStyle: small.copyWith(fontWeight: FontWeight.w700),
                  ),
                  child: Text('Save $count ${count == 1 ? 'name' : 'names'}'),
                ),
              ),
            ],
          ),
        ],
      ),
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
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          );
          final selectedNames = _selected
              .whereType<_AreaNode>()
              .map((node) => node.name)
              .toList();
          final path = selectedNames.isEmpty
              ? widget.projectName
              : selectedNames.join(' › ');
          final parentNames = _selected
              .take(_addingLevel ?? 0)
              .whereType<_AreaNode>()
              .map((node) => node.name)
              .toList();
          final parentPath = parentNames.isEmpty
              ? widget.projectName
              : parentNames.join(' › ');
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _editLabels,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(44 * s, 14 * s),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Edit labels',
                      style: text(8, bold: true, color: _lime),
                    ),
                  ),
                ),
                Text(widget.projectName, style: text(8)),
                SizedBox(height: 14 * s),
                Expanded(
                  child: SingleChildScrollView(
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
                                _addingLevel == null
                                    ? 'Selected area'
                                    : 'Adding under',
                                style: text(8, bold: true),
                              ),
                              SizedBox(height: 5 * s),
                              Text(
                                _addingLevel == null ? path : parentPath,
                                style: text(10, bold: true, color: _white),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10 * s),
                        for (var i = 0; i < 4; i++) ...[
                          Text(_labels[i], style: text(9, bold: true)),
                          SizedBox(height: 2 * s),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8 * s,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _surface,
                                    border: Border.all(
                                      color: _border,
                                      width: .7,
                                    ),
                                    borderRadius: BorderRadius.circular(8 * s),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<_AreaNode>(
                                      value: _selected[i],
                                      isExpanded: true,
                                      dropdownColor: _surface,
                                      style: text(9, color: _white),
                                      icon: Icon(
                                        Icons.expand_more,
                                        color: _muted,
                                        size: 12 * s,
                                      ),
                                      hint: Text(
                                        (i == 0 || _selected[i - 1] != null)
                                            ? 'Select ${_labels[i].toLowerCase()}'
                                            : 'Choose ${_labels[i - 1].toLowerCase()} first',
                                        style: text(9),
                                      ),
                                      items: _options(i)
                                          .map(
                                            (node) => DropdownMenuItem(
                                              value: node,
                                              child: Text(node.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) _select(i, value);
                                      },
                                      itemHeight: null,
                                      isDense: true,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 9 * s,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 7 * s),
                              SizedBox(
                                width: 55 * s,
                                height: 31 * s,
                                child: OutlinedButton(
                                  onPressed: i == 0 || _selected[i - 1] != null
                                      ? () => _add(i)
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    foregroundColor: _lime,
                                    disabledForegroundColor: _muted,
                                    side: BorderSide(
                                      color: i == 0 || _selected[i - 1] != null
                                          ? _lime
                                          : _border,
                                      width: .7,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        8 * s,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '+ Add',
                                    style: text(
                                      9,
                                      bold: true,
                                      color: i == 0 || _selected[i - 1] != null
                                          ? _lime
                                          : _muted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_addingLevel == i) _addForm(s),
                          SizedBox(height: 6 * s),
                        ],
                        SizedBox(height: 28 * s),
                        Text(
                          'Choose a parent first. Each bar shows only the names saved under it.',
                          style: text(9),
                        ),
                        SizedBox(height: 12 * s),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12 * s),
                FilledButton(
                  onPressed: () {
                    if (_addingLevel != null) {
                      _saveNames();
                    } else {
                      FocusScope.of(context).unfocus();
                    }
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
