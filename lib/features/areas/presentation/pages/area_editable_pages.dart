import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/theme/app_theme.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AreaEditablePage extends StatefulWidget {
  const AreaEditablePage({
    super.key,
    this.projectName = 'Laxmi Gauri',
    this.projectId,
    this.labels = const ['Building', 'Level', 'Apartment', 'Room'],
    this.aboutAreas = '',
  });

  final String projectName;
  final String? projectId;
  final List<String> labels;
  final String aboutAreas;

  @override
  State<AreaEditablePage> createState() => _AreaEditablePageState();
}

class _AreaNode {
  _AreaNode(this.name, [List<_AreaNode>? children])
      : children = children ?? [];

  String name;
  final List<_AreaNode> children;

  Map<String, dynamic> toJson() => {
        'name': name,
        'children': children.map((node) => node.toJson()).toList(),
      };

  factory _AreaNode.fromJson(Map<String, dynamic> json) => _AreaNode(
        (json['name'] ?? '').toString(),
        ((json['children'] as List?) ?? [])
            .map((item) => _AreaNode.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class _AreaEditablePageState extends State<AreaEditablePage> {
  static const _bg = Color(0xFF092A3B);
  static const _surface = Color(0xFF123448);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF9FC1D5);
  static const _white = Color(0xFFF0F4FC);
  static const _primaryAccent = AppColors.primary;

  final List<_AreaNode> _roots = [];
  final List<_AreaNode?> _selected = List<_AreaNode?>.filled(4, null);
  final _input = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _scroll = ScrollController();

  late final List<String> _labels;
  late final String _storageKey;
  String _about = '';
  String? _error;
  String? _notice;
  int _step = 0;
  bool _numberedOpen = false;
  bool _loading = true;
  Future<void> _pendingSave = Future<void>.value();

  @override
  void initState() {
    super.initState();
    const defaults = ['Building', 'Level', 'Apartment', 'Room'];
    _labels = List.generate(4, (i) {
      final value = i < widget.labels.length ? widget.labels[i].trim() : '';
      return value.isEmpty ? defaults[i] : value;
    });
    _about = widget.aboutAreas;
    _storageKey = 'area_setup_v2_${widget.projectId ?? widget.projectName}';
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null) {
        final data = Map<String, dynamic>.from(jsonDecode(saved) as Map);
        final roots = ((data['roots'] as List?) ?? [])
            .map((e) => _AreaNode.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (!mounted) return;
        _roots.addAll(roots);
        final names = ((data['selectedPath'] as List?) ?? [])
            .map((e) => e.toString())
            .toList();
        List<_AreaNode> siblings = _roots;
        for (var i = 0; i < names.length && i < 4; i++) {
          _AreaNode? found;
          for (final node in siblings) {
            if (node.name == names[i]) {
              found = node;
              break;
            }
          }
          if (found == null) break;
          _selected[i] = found;
          siblings = found.children;
        }
        _step = (data['step'] is int ? data['step'] as int : 0).clamp(0, 3);
        if (_step > 0 && _selected[_step - 1] == null) _step = 0;
        _about = (data['aboutAreas'] ?? _about).toString();
      }
    } catch (e) {
      // A corrupt local draft must not prevent creating a fresh hierarchy.
      _notice = 'Unable to restore the saved draft.';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<_AreaNode> _items(int step) =>
      step == 0 ? _roots : (_selected[step - 1]?.children ?? []);

  List<String> get _path {
    final path = <String>[];
    for (final node in _selected) {
      if (node == null) break;
      path.add(node.name);
    }
    return path;
  }

  Map<String, dynamic> _snapshot() => {
        'projectName': widget.projectName,
        'labels': _labels,
        'aboutAreas': _about,
        'roots': _roots.map((e) => e.toJson()).toList(),
        'selectedPath': _path,
        'step': _step,
      };

  Future<void> _save() {
    // Serialize writes so a slow earlier write cannot overwrite a newer one.
    final encoded = jsonEncode(_snapshot());
    _pendingSave = _pendingSave.catchError((_) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, encoded);
    });
    return _pendingSave;
  }

  void _clearEntry() {
    _input.clear();
    _from.clear();
    _to.clear();
    _error = null;
    _notice = null;
    _numberedOpen = false;
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _step--;
      _clearEntry();
    });
    _save();
  }

  void _choose(_AreaNode node) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selected[_step] = node;
      for (int i = _step + 1; i < 4; i++) {
        _selected[i] = null;
      }
      if (_step < 3) _step++;
      _clearEntry();
    });
    _scrollToTop();
    _save();
  }

  void _scrollToTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _addNames() {
    final names = _input.text
        .split(RegExp(r'[,\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      setState(() => _error = 'Enter at least one name.');
      return;
    }
    final items = _items(_step);
    final existing = items.map((e) => e.name.toLowerCase()).toSet();
    final added = <_AreaNode>[];
    for (final name in names) {
      if (existing.add(name.toLowerCase())) added.add(_AreaNode(name));
    }
    if (added.isEmpty) {
      setState(() => _error = 'These names already exist.');
      return;
    }
    setState(() {
      items.addAll(added);
      _input.clear();
      _error = null;
      _notice = '${added.length} added.';
    });
    FocusScope.of(context).unfocus();
    _save();
  }

  void _addNumbers() {
    final first = int.tryParse(_from.text.trim());
    final last = int.tryParse(_to.text.trim());
    if (first == null || last == null || first < 0 || last < first) {
      setState(() => _error = 'Enter a valid From and To number.');
      return;
    }
    if (last - first > 500) {
      setState(() => _error = 'Add up to 501 numbers at a time.');
      return;
    }
    final items = _items(_step);
    final existing = items.map((e) => e.name.toLowerCase()).toSet();
    final prefix = _labels[_step];
    final added = <_AreaNode>[];
    for (var number = first; number <= last; number++) {
      final name = '$prefix $number';
      if (existing.add(name.toLowerCase())) added.add(_AreaNode(name));
    }
    if (added.isEmpty) {
      setState(() => _error = 'All these numbered entries exist.');
      return;
    }
    setState(() {
      items.addAll(added);
      _from.clear();
      _to.clear();
      _error = null;
      _notice = '${added.length} added.';
    });
    FocusScope.of(context).unfocus();
    _save();
  }

  Future<void> _editItem(_AreaNode node) async {
    final controller = TextEditingController(text: node.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceColor(_surface),
        title: Text('Rename', style: TextStyle(color: context.foregroundColor(_white))),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: context.foregroundColor(_white)),
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: context.mutedColor(_muted)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text('Save', style: TextStyle(color: context.accentColor(_primaryAccent))),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || newName == null || newName.isEmpty) return;
    final taken = _items(_step).any((e) =>
        !identical(e, node) && e.name.toLowerCase() == newName.toLowerCase());
    if (taken) {
      setState(() => _error = 'That name already exists.');
      return;
    }
    setState(() => node.name = newName);
    _save();
  }

  Future<void> _deleteItem(_AreaNode node) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceColor(_surface),
        title: Text('Delete area?', style: TextStyle(color: context.foregroundColor(_white))),
        content: Text(
          'Delete "${node.name}" and all its nested areas?',
          style: TextStyle(color: context.mutedColor(_muted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    setState(() {
      _items(_step).remove(node);
      if (identical(_selected[_step], node)) {
        for (var i = _step; i < 4; i++) _selected[i] = null;
      }
    });
    _save();
  }

  Future<void> _finish() async {
    FocusScope.of(context).unfocus();
    try {
      await _save();
      if (!mounted) return;
      Navigator.of(context).pop(_snapshot());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save setup locally. Try again.')),
      );
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _from.dispose();
    _to.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _title {
    switch (_step) {
      case 0: return '${_labels[0]}s';
      case 1: return '${_labels[1]}s';
      case 2: return '${_labels[2]}s & areas';
      default: return '${_labels[3]}s';
    }
  }

  String get _fieldTitle {
    switch (_step) {
      case 0: return '${_labels[0]} names';
      case 1: return '${_labels[1]} names or numbers';
      case 2: return '${_labels[2]} or other area names';
      default: return '${_labels[3]} names';
    }
  }

  String get _listTitle => _step == 2 ? '${_labels[2]}s and other areas' : _title;

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.mutedColor(_muted), fontSize: 15),
        filled: true,
        fillColor: context.surfaceColor(_surface),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: context.borderColor(_border)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: context.accentColor(_primaryAccent), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _addButton(VoidCallback callback, {double width = 74, double height = 80}) =>
      SizedBox(
        width: width,
        height: height,
        child: FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(
            backgroundColor: _primaryAccent,
            foregroundColor: _bg,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      );

  Widget _numberedSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _numberedOpen = !_numberedOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Add numbered ${_labels[_step].toLowerCase()}s',
                        style: TextStyle(color: context.mutedColor(_muted), fontSize: 13)),
                  ),
                  Icon(_numberedOpen ? Icons.remove : Icons.add, color: context.accentColor(_primaryAccent), size: 19),
                ],
              ),
            ),
          ),
          if (_numberedOpen) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _numberField('From', _from, '1')),
                const SizedBox(width: 8),
                Expanded(child: _numberField('To', _to, 'Last number')),
                const SizedBox(width: 8),
                _addButton(_addNumbers, width: 65, height: 47),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Divider(color: context.borderColor(_border), height: 1),
        ],
      );

  Widget _numberField(String label, TextEditingController controller, String hint) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.mutedColor(_muted), fontSize: 12)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: context.foregroundColor(_white)),
            decoration: _decoration(hint).copyWith(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
            ),
          ),
        ],
      );

  Widget _entryTile(_AreaNode node) => InkWell(
        onTap: () => _choose(node),
        onLongPress: () => _showItemActions(node),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: _step == 1 ? Alignment.center : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: context.surfaceColor(_surface),
            border: Border.all(color: context.borderColor(_border)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            node.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.foregroundColor(_white), fontSize: 14),
          ),
        ),
      );

  void _showItemActions(_AreaNode node) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor(_surface),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: context.foregroundColor(_white)),
              title: Text('Rename', style: TextStyle(color: context.foregroundColor(_white))),
              onTap: () { Navigator.pop(sheetContext); _editItem(node); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onTap: () { Navigator.pop(sheetContext); _deleteItem(node); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.backgroundColor(_bg),
        body: SafeArea(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: context.accentColor(_primaryAccent)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 24, 12),
                      child: Row(
                        children: [
                          if (_step > 0)
                            IconButton(
                              onPressed: _goBack,
                              icon: Icon(Icons.chevron_left, color: context.foregroundColor(_white), size: 30),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 34),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_title, style: TextStyle(
                                  color: context.foregroundColor(_white), fontWeight: FontWeight.w600, fontSize: 23)),
                                const SizedBox(height: 3),
                                Text(
                                  [widget.projectName, ..._selected.take(_step).whereType<_AreaNode>().map((e) => e.name)].join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: context.mutedColor(_muted), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _finish,
                            child: Text('Save & Exit', style: TextStyle(
                              color: context.accentColor(_primaryAccent), fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: context.borderColor(_border), height: 1),
                    Expanded(
                      child: ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                        children: [
                          Text(_fieldTitle, style: TextStyle(
                              color: context.foregroundColor(_white), fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 9),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _input,
                                  minLines: 3,
                                  maxLines: 4,
                                  textCapitalization: TextCapitalization.words,
                                  style: TextStyle(color: context.foregroundColor(_white)),
                                  decoration: _decoration(
                                    _step == 0 ? 'Building A, Building B' :
                                    _step == 1 ? 'Ground, First, Roof, Parking' :
                                    _step == 2 ? 'Apt A, Penthouse, East Corridor' :
                                    'Kitchen, Bedroom, Bathroom',
                                  ),
                                  onChanged: (_) {
                                    if (_error != null) setState(() => _error = null);
                                  },
                                ),
                              ),
                              const SizedBox(width: 7),
                              _addButton(_addNames),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                            ),
                          Text('Separate names with commas or new lines.',
                              style: TextStyle(color: context.mutedColor(_muted), fontSize: 12)),
                          if (_notice != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Text(_notice!, style: TextStyle(color: context.mutedColor(_muted), fontSize: 12)),
                            ),
                          const SizedBox(height: 10),
                          _numberedSection(),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Text(_listTitle, style: TextStyle(
                                    color: context.foregroundColor(_white), fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
                              Text('${_items(_step).length}',
                                  style: TextStyle(color: context.mutedColor(_muted), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_items(_step).isEmpty)
                            Text('No entries yet. Add names above, or tap Done to finish here.',
                                style: TextStyle(color: context.mutedColor(_muted), fontSize: 13))
                          else if (_step == 0)
                            ..._items(_step).map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _entryTile(e),
                                ))
                          else
                            LayoutBuilder(
                              builder: (context, limits) {
                                final count = limits.maxWidth >= 620 ? 3 : 2;
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: count,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    mainAxisExtent: 49,
                                  ),
                                  itemCount: _items(_step).length,
                                  itemBuilder: (_, index) => _entryTile(_items(_step)[index]),
                                );
                              },
                            ),
                          const SizedBox(height: 24),
                          Text('Tap an entry to continue into it. Long-press to rename or delete.',
                              style: TextStyle(color: context.mutedColor(_muted), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      );
}

