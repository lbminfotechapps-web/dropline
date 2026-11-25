import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/theme/app_theme.dart';
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
  final String projectId, companyId, projectName, companyName;
  @override
  State<ProjectEventPage> createState() => _ProjectEventPageState();
}

class _EventCategory {
  _EventCategory(this.name, this.events);
  String name;
  List<String> events;
  Map<String, dynamic> toJson() => {'name': name, 'events': events};
  factory _EventCategory.fromJson(dynamic value) => _EventCategory(
    value['name'] as String,
    List<String>.from(value['events'] as List),
  );
}

class _ProjectEventPageState extends State<ProjectEventPage> {
  Color get bg => context.backgroundColor(const Color(0xFF092A3B));
  Color get surface => context.surfaceColor(const Color(0xFF123449));
  Color get border => context.borderColor(const Color(0xFF31576B));
  Color get muted => context.mutedColor(const Color(0xFF9FC1D7));
  Color get white => context.foregroundColor(const Color(0xFFF0F4FC));
  static const primaryAccent = AppColors.primary;
  final categories = <_EventCategory>[];
  final addText = TextEditingController(),
      editText = TextEditingController(),
      categoryText = TextEditingController();
  int selected = 0;
  int? editing;
  bool newCategory = false, loading = true, closing = false, loadFailed = false;
  Future<void> pendingSave = Future.value();
  String get keyName =>
      'project_event_categories_v1:${jsonEncode([widget.companyId.isEmpty ? widget.companyName : widget.companyId, widget.projectId.isEmpty ? widget.projectName : widget.projectId])}';
  _EventCategory? get current =>
      categories.isEmpty ? null : categories[selected];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    addText.dispose();
    editText.dispose();
    categoryText.dispose();
    super.dispose();
  }

  void error(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(keyName);
      final values = raw == null
          ? [
              _EventCategory('Quality', [
                'Workmanship issue',
                'Drawing mismatch',
              ]),
              _EventCategory('Safety', ['Trip hazard']),
              _EventCategory('Progress', ['Work completed']),
            ]
          : (jsonDecode(raw) as List).map(_EventCategory.fromJson).toList();
      if (mounted)
        setState(() {
          categories.addAll(values);
          loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          loading = false;
          loadFailed = true;
        });
      error('Unable to load existing events.');
    }
  }

  Future<void> save() {
    final snapshot = jsonEncode(categories.map((c) => c.toJson()).toList());
    final write = pendingSave.catchError((Object _) {}).then((_) async {
      final ok = await (await SharedPreferences.getInstance()).setString(
        keyName,
        snapshot,
      );
      if (!ok) throw StateError('Local save failed');
    });
    pendingSave = write;
    write.catchError((Object _) {
      error('Could not save locally. Tap Done to retry.');
    });
    return write;
  }

  List<String> parsed(String s) => s
      .split(RegExp(r'[,\r\n]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  bool addEvents({bool optional = false}) {
    if (current == null) {
      error('Create a category first');
      return false;
    }
    final names = parsed(addText.text);
    if (names.isEmpty) {
      if (!optional) error('Enter an event');
      return optional;
    }
    final known = current!.events.map((e) => e.toLowerCase()).toSet();
    final added = names.where((e) => known.add(e.toLowerCase())).toList();
    if (added.isEmpty) {
      error('Events already exist');
      return false;
    }
    setState(() {
      current!.events.addAll(added);
      addText.clear();
    });
    FocusManager.instance.primaryFocus?.unfocus();
    save();
    return true;
  }

  bool createCategory({bool optional = false}) {
    final name = categoryText.text.trim();
    if (name.isEmpty) {
      if (!optional) error('Enter category name');
      return optional;
    }
    if (categories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      error('Category already exists');
      return false;
    }
    setState(() {
      categories.add(_EventCategory(name, []));
      selected = categories.length - 1;
      newCategory = false;
      categoryText.clear();
      editing = null;
      addText.clear();
    });
    FocusManager.instance.primaryFocus?.unfocus();
    save();
    return true;
  }

  void startEdit(int index) {
    setState(() {
      editing = index;
      editText.text = current!.events[index];
    });
  }

  bool saveEdit() {
    if (editing == null || current == null) return true;
    final value = editText.text.trim();
    if (value.isEmpty) {
      error('Enter event name');
      return false;
    }
    if (current!.events.asMap().entries.any(
      (e) => e.key != editing && e.value.toLowerCase() == value.toLowerCase(),
    )) {
      error('Event already exists');
      return false;
    }
    setState(() {
      current!.events[editing!] = value;
      editing = null;
      editText.clear();
    });
    FocusManager.instance.primaryFocus?.unfocus();
    save();
    return true;
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;
    setState(() {
      final item = current!.events.removeAt(oldIndex);
      current!.events.insert(newIndex, item);
      if (editing != null) {
        if (editing == oldIndex)
          editing = newIndex;
        else if (oldIndex < editing! && editing! <= newIndex)
          editing = editing! - 1;
        else if (newIndex <= editing! && editing! < oldIndex)
          editing = editing! + 1;
      }
    });
    save();
  }

  Future<void> done() async {
    if (closing || loading || loadFailed) return;
    if (!saveEdit()) return;
    if (newCategory && !createCategory(optional: true)) return;
    if (addText.text.trim().isNotEmpty && !addEvents()) return;
    setState(() => closing = true);
    try {
      try {
        await pendingSave;
      } catch (_) {
        /* Final write retries. */
      }
      final ok = await (await SharedPreferences.getInstance()).setString(
        keyName,
        jsonEncode(categories.map((c) => c.toJson()).toList()),
      );
      if (!ok) throw StateError('Write failed');
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      error('Unable to save events. Try again.');
    } finally {
      if (mounted) setState(() => closing = false);
    }
  }

  InputDecoration field(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: muted),
    filled: true,
    fillColor: surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: BorderSide(color: context.accentColor(primaryAccent), width: 1.7),
    ),
  );
  Widget action(String text, VoidCallback? press, {double height = 78}) =>
      SizedBox(
        width: 70,
        height: height,
        child: FilledButton(
          onPressed: press,
          style: FilledButton.styleFrom(
            backgroundColor: primaryAccent,
            foregroundColor: bg,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final section = TextStyle(
      fontSize: 15,
      color: white,
      fontWeight: FontWeight.w600,
    );
    final help = TextStyle(fontSize: 12, color: muted);
    final c = current;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 5, 15, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Events',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            color: white,
                          ),
                        ),
                        Text(widget.projectName, style: help),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: (loading || closing || loadFailed) ? null : done,
                    child: Text(
                      closing ? 'Saving...' : 'Done',
                      style: TextStyle(
                        color: context.accentColor(primaryAccent),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: border, height: 1),
            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator(color: context.accentColor(primaryAccent)))
                  : loadFailed
                  ? Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            loadFailed = false;
                            loading = true;
                          });
                          load();
                        },
                        child: const Text('Could not load events. Retry'),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 13, 14, 35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Category', style: help),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: surface,
                                    border: Border.all(color: border),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: categories.isEmpty
                                      ? Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'No categories',
                                            style: help,
                                          ),
                                        )
                                      : DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            isExpanded: true,
                                            dropdownColor: surface,
                                            value: selected,
                                            style: TextStyle(
                                              color: white,
                                              fontSize: 15,
                                            ),
                                            iconEnabledColor: white,
                                            items: [
                                              for (
                                                int i = 0;
                                                i < categories.length;
                                                i++
                                              )
                                                DropdownMenuItem(
                                                  value: i,
                                                  child: Text(
                                                    categories[i].name,
                                                  ),
                                                ),
                                            ],
                                            onChanged: (v) {
                                              if (v == null ||
                                                  (editing != null &&
                                                      !saveEdit()))
                                                return;
                                              setState(() {
                                                selected = v;
                                                editing = null;
                                                addText.clear();
                                              });
                                            },
                                          ),
                                        ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => newCategory = !newCategory),
                                child: Text(
                                  '+ New',
                                  style: TextStyle(color: context.accentColor(primaryAccent)),
                                ),
                              ),
                            ],
                          ),
                          if (newCategory) ...[
                            const SizedBox(height: 19),
                            Text('New category', style: section),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: categoryText,
                                    autofocus: true,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    style: TextStyle(color: white),
                                    decoration: field('Category name'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                action('Add', createCategory, height: 50),
                              ],
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                newCategory = false;
                                categoryText.clear();
                              }),
                              child: Text('Cancel', style: help),
                            ),
                          ],
                          const SizedBox(height: 25),
                          if (editing != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Edit event', style: section),
                                TextButton(
                                  onPressed: () => setState(() {
                                    editing = null;
                                    editText.clear();
                                  }),
                                  child: Text('Cancel edit', style: help),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: editText,
                                    minLines: 2,
                                    maxLines: 3,
                                    autofocus: true,
                                    style: TextStyle(
                                      color: white,
                                      fontSize: 16,
                                    ),
                                    decoration: field('Event name'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                action('Save', saveEdit),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('One event per line.', style: help),
                          ] else ...[
                            Text('Add events', style: section),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: addText,
                                    minLines: 2,
                                    maxLines: 5,
                                    style: TextStyle(
                                      color: white,
                                      fontSize: 16,
                                    ),
                                    decoration: field(
                                      'Workmanship issue\nInspection needed',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                action('Add', c == null ? null : addEvents),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('One event per line.', style: help),
                          ],
                          const SizedBox(height: 35),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${c?.name ?? 'Category'} events',
                                  style: section,
                                ),
                              ),
                              Text('${c?.events.length ?? 0}', style: help),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Drag a grip to reorder. Tap it for up / down.',
                            style: help,
                          ),
                          const SizedBox(height: 12),
                          if (c != null)
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              itemCount: c.events.length,
                              onReorder: reorder,
                              proxyDecorator: (child, index, animation) =>
                                  Material(
                                    color: surface,
                                    elevation: 3,
                                    child: child,
                                  ),
                              itemBuilder: (context, index) => Container(
                                key: ValueKey('${selected}_${c.events[index]}'),
                                height: 59,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: border),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 42,
                                      child:
                                          ReorderableDelayedDragStartListener(
                                            index: index,
                                            child: PopupMenuButton<String>(
                                              tooltip: 'Move event',
                                              color: surface,
                                              icon: Icon(
                                                Icons.drag_indicator,
                                                color: muted,
                                              ),
                                              itemBuilder: (_) => [
                                                if (index > 0)
                                                  PopupMenuItem(
                                                    value: 'up',
                                                    child: Text(
                                                      'Move up',
                                                      style: TextStyle(
                                                        color: white,
                                                      ),
                                                    ),
                                                  ),
                                                if (index < c.events.length - 1)
                                                  PopupMenuItem(
                                                    value: 'down',
                                                    child: Text(
                                                      'Move down',
                                                      style: TextStyle(
                                                        color: white,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                              onSelected: (direction) =>
                                                  reorder(
                                                    index,
                                                    direction == 'up'
                                                        ? index - 1
                                                        : index + 2,
                                                  ),
                                            ),
                                          ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        c.events[index],
                                        style: TextStyle(
                                          color: white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => startEdit(index),
                                      child: Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
