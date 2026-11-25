import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/theme/app_theme.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:intl/intl.dart';
import 'package:dropline/features/pdf_editor_page.dart';
import 'photo_editor_page.dart';

import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/event/data/repositories/event_draft_store.dart';
import '../widgets/event_attachment_preview.dart';

class MyUpdatesPage extends StatefulWidget {
  const MyUpdatesPage({super.key, this.recordsLoader});

  final Future<List<EventDraftRecord>> Function()? recordsLoader;

  @override
  State<MyUpdatesPage> createState() => _MyUpdatesPageState();
}

class _MyUpdatesPageState extends State<MyUpdatesPage> {
  static const _background = Color(0xFF0C2938);
  static const _surface = Color(0xFF173B4B);
  static const _muted = Color(0xFFA5C1CF);
  static const _border = Color(0xFF2B4C5B);
  static const _accent = AppColors.primary;
  final _store = EventDraftStore();
  List<EventDraftRecord> _records = [];
  bool _loading = true;
  String? _error;
  String? _selectedProject;
  int _selectedType = 0;
  int _dateFilter = 0;
  String? _selectedArea;
  String? _selectedCategory;
  String? _selectedEvent;
  bool _oldestFirst = false;

  int get _filterCount => [
    _selectedProject != null,
    _selectedArea != null,
    _selectedCategory != null,
    _selectedEvent != null,
    _dateFilter != 0,
    _oldestFirst,
  ].where((active) => active).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      List<EventDraftRecord> records;
      if (widget.recordsLoader != null) {
        records = await widget.recordsLoader!();
      } else {
        final login = await sl<SecureStorage>().readLoginResponse();
        records = login == null || login.result.isEmpty
            ? []
            : await _store.records(userId: login.result.first.userId);
      }
      if (!mounted) return;
      setState(() {
        _records = records;
        if (!records.any((record) => record.projectName == _selectedProject)) {
          _selectedProject = null;
        }
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load your records. Please retry.';
        _loading = false;
      });
    }
  }

  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

  List<EventDraftRecord> get _filtered => _matching(
    project: _selectedProject,
    area: _selectedArea,
    category: _selectedCategory,
    event: _selectedEvent,
    dateFilter: _dateFilter,
    oldestFirst: _oldestFirst,
  );

  List<EventDraftRecord> _matching({
    String? project,
    String? area,
    String? category,
    String? event,
    int dateFilter = 0,
    bool oldestFirst = false,
  }) {
    final today = _day(DateTime.now());
    final types = [
      null,
      EventItemType.photo,
      EventItemType.note,
      EventItemType.audio,
    ];
    return _records.where((record) {
      if (project != null && record.projectName != project) {
        return false;
      }
      if (types[_selectedType] != null &&
          record.item.type != types[_selectedType]) {
        return false;
      }
      if (area != null && record.item.area != area) return false;
      if (category != null && record.item.category != category) return false;
      if (event != null && record.item.event != event) return false;
      final date = _day(record.date);
      return switch (dateFilter) {
        1 => date == today,
        2 => date == DateTime(today.year, today.month, today.day - 1),
        3 =>
          !date.isBefore(DateTime(today.year, today.month, today.day - 6)) &&
              !date.isAfter(today),
        _ => true,
      };
    }).toList()..sort((a, b) {
      final byDay = b.date.compareTo(a.date);
      final order = byDay != 0
          ? byDay
          : (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date);
      return oldestFirst ? -order : order;
    });
  }

  String _dayLabel(DateTime date) {
    final today = _day(DateTime.now());
    if (date == today) return 'Today';
    if (date == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    return DateFormat('EEEE, d MMM').format(date);
  }

  Future<void> _showFilters() async {
    var project = _selectedProject;
    var area = _selectedArea;
    var category = _selectedCategory;
    var event = _selectedEvent;
    var date = _dateFilter;
    var oldest = _oldestFirst;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.backgroundColor(Color(0xFF122C3B)),
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: context.borderColor(_border)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          List<String> options(Iterable<String> values) =>
              values.where((s) => s.isNotEmpty).toSet().toList()..sort();
          final projects = options(_records.map((r) => r.projectName));
          final scoped = _records.where(
            (r) => project == null || r.projectName == project,
          );
          final areas = options(scoped.map((r) => r.item.area));
          final categories = options(scoped.map((r) => r.item.category));
          final events = options(
            scoped
                .where((r) => r.item.category == category)
                .map((r) => r.item.event),
          );
          if (!projects.contains(project)) project = null;
          if (!areas.contains(area)) area = null;
          if (!categories.contains(category)) category = null;
          if (!events.contains(event)) event = null;
          final count = _matching(
            project: project,
            area: area,
            category: category,
            event: event,
            dateFilter: date,
            oldestFirst: oldest,
          ).length;

          Widget field(
            String label,
            String value,
            Map<String, String> entries,
            ValueChanged<String>? changed,
          ) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFBDD5E2),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                key: ValueKey('$label:$value:${entries.keys.join(',')}'),
                initialValue: value,
                isExpanded: true,
                dropdownColor: context.surfaceColor(const Color(0xFF122C3B)),
                style: TextStyle(
                  color: context.foregroundColor(Colors.white),
                  fontSize: 13,
                ),
                iconEnabledColor: context.foregroundColor(Colors.white),
                iconDisabledColor: context.foregroundColor(Colors.white),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: context.foregroundColor(Colors.white),
                  size: 20,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.surfaceColor(Color(0xFF102633)),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(color: context.borderColor(_border)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(color: context.borderColor(_border)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(color: context.accentColor(_accent)),
                  ),
                ),
                items: entries.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.foregroundColor(Colors.white),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: changed == null
                    ? null
                    : (v) {
                        if (v != null) changed(v);
                      },
              ),
            ],
          );
          return SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Filters',
                                  style: TextStyle(
                                    color: context.foregroundColor(
                                      Colors.white,
                                    ),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
                              IconButton.outlined(
                                tooltip: 'Close filters',
                                onPressed: () => Navigator.pop(context),
                                style: IconButton.styleFrom(
                                  foregroundColor: context.mutedColor(_muted),
                                  side: BorderSide(
                                    color: context.borderColor(_border),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                                icon: const Icon(Icons.close, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          field(
                            'Project',
                            project ?? '',
                            {
                              '': 'All projects',
                              for (final p in projects) p: p,
                            },
                            (v) => update(() {
                              project = v.isEmpty ? null : v;
                              area = null;
                              category = null;
                              event = null;
                            }),
                          ),
                          const SizedBox(height: 10),
                          field(
                            'Area',
                            area ?? '',
                            {
                              '': project == null
                                  ? 'Choose project first'
                                  : areas.isEmpty
                                  ? 'No areas available'
                                  : 'Any area',
                              for (final a in areas) a: a,
                            },
                            project == null || areas.isEmpty
                                ? null
                                : (v) =>
                                      update(() => area = v.isEmpty ? null : v),
                          ),
                          const SizedBox(height: 10),
                          field(
                            'Category',
                            category ?? '',
                            {
                              '': 'Any category',
                              for (final c in categories) c: c,
                            },
                            (v) => update(() {
                              category = v.isEmpty ? null : v;
                              event = null;
                            }),
                          ),
                          const SizedBox(height: 10),
                          field(
                            'Event',
                            event ?? '',
                            {
                              '': category == null
                                  ? 'Choose category first'
                                  : events.isEmpty
                                  ? 'No events available'
                                  : 'Any event',
                              for (final e in events) e: e,
                            },
                            category == null || events.isEmpty
                                ? null
                                : (v) => update(
                                    () => event = v.isEmpty ? null : v,
                                  ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: field(
                                  'Date',
                                  '$date',
                                  const {
                                    '0': 'Any date',
                                    '1': 'Today',
                                    '2': 'Yesterday',
                                    '3': 'Last 7 days',
                                  },
                                  (v) => update(() => date = int.parse(v)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: field(
                                  'Sort',
                                  oldest ? 'oldest' : 'newest',
                                  const {
                                    'newest': 'Newest first',
                                    'oldest': 'Oldest first',
                                  },
                                  (v) => update(() => oldest = v == 'oldest'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: context.borderColor(_border)),
                      ),
                    ),
                    child: Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => update(() {
                            project = null;
                            area = null;
                            category = null;
                            event = null;
                            date = 0;
                            oldest = false;
                          }),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.mutedColor(_muted),
                            backgroundColor: context.surfaceColor(_surface),
                            minimumSize: const Size(64, 46),
                            side: BorderSide(
                              color: context.borderColor(_border),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text('Clear'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: _background,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            child: Text(
                              'Show $count ${count == 1 ? 'record' : 'records'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || applied != true) return;
    setState(() {
      _selectedProject = project;
      _selectedArea = area;
      _selectedCategory = category;
      _selectedEvent = event;
      _dateFilter = date;
      _oldestFirst = oldest;
    });
  }

  Future<EventDraftRecord?> _editRecord(EventDraftRecord record) async {
    try {
      final item = record.item;
      if (item.type == EventItemType.note) {
        final controller = TextEditingController(text: item.text);
        final text = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Edit note'),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 4,
              maxLines: 10,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        controller.dispose();
        if (text == null) return null;
        final scope = record.scope;
        if (scope == null) throw StateError('Draft scope is unavailable');
        final items = await _store.load(scope);
        final index = items.indexWhere((entry) => entry.id == item.id);
        if (index < 0) throw StateError('Note is no longer available');
        items[index] = items[index].withText(text);
        await _store.save(scope, items);
        return EventDraftRecord(
          date: record.date,
          item: items[index],
          file: record.file,
          projectName: record.projectName,
          scope: scope,
        );
      }
      if (item.type == EventItemType.audio) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice recordings cannot be edited.')),
          );
        return null;
      }
      final file = record.file;
      if (file == null || !await file.exists())
        throw StateError('File is unavailable');
      Future<void> saveBytes(List<int> bytes) async {
        if (record.scope != null) {
          await _store.replaceFile(record.scope!, item, bytes);
        } else {
          final temporary = File('${file.path}.tmp');
          await temporary.writeAsBytes(bytes, flush: true);
          await temporary.rename(file.path);
        }
      }

      if (!mounted) return null;
      final bool? saved;
      if (item.type == EventItemType.photo) {
        saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PhotoEditorPage(file: file, onSave: saveBytes),
          ),
        );
        if (saved == true) await FileImage(file).evict();
      } else {
        final bytes = await file.readAsBytes();
        if (!mounted) return null;
        saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PdfEditorPage(
              initialBytes: bytes,
              fileName: item.name,
              onSave: saveBytes,
            ),
          ),
        );
      }
      return saved == true ? record : null;
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to edit this update. Please try again.'),
          ),
        );
      return null;
    }
  }

  Future<bool> _confirmDeleteImage(EventDraftRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceColor(_surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete attachment?',
          style: TextStyle(color: context.foregroundColor(Colors.white)),
        ),
        content: Text(
          'Are you sure you want to delete this attachment? '
          'This action cannot be undone.',
          style: TextStyle(color: context.mutedColor(Colors.white70)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.mutedColor(Colors.white70)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;
    try {
      final scope = record.scope;
      if (scope == null) throw StateError('Draft scope is unavailable');
      final items = await _store.load(scope);
      final index = items.indexWhere((item) => item.id == record.item.id);
      if (index < 0) throw StateError('Update is no longer available');
      final removed = items.removeAt(index);
      await _store.save(scope, items);
      if (removed.fileName != null &&
          !items.any((item) => item.fileName == removed.fileName)) {
        try {
          final file = await _store.file(scope, removed);
          if (await file.exists()) await file.delete();
        } catch (_) {
          // Metadata is already saved; an orphaned file can be cleaned up later.
        }
      }
      if (mounted) {
        setState(
          () => _records.removeWhere(
            (entry) => entry.scope == scope && entry.item.id == record.item.id,
          ),
        );
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete this update. Please try again.'),
          ),
        );
      }
      return false;
    }
  }

  Future<Size?> _photoSize(EventDraftRecord record) async {
    final file = record.file;
    if (record.item.type != EventItemType.photo || file == null) return null;
    try {
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      try {
        final frame = await codec.getNextFrame();
        final size = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
        frame.image.dispose();
        return size;
      } finally {
        codec.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  void _open(EventDraftRecord record) {
    var current = record;
    var previewVersion = 0;
    var photoSize = _photoSize(record);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StatefulBuilder(
          builder: (context, refresh) {
            final record = current;
            return Scaffold(
              backgroundColor: context.backgroundColor(_background),
              appBar: AppBar(
                backgroundColor: context.backgroundColor(_background),
                foregroundColor: context.foregroundColor(Colors.white),
                elevation: 0,
                title: Text(switch (record.item.type) {
                  EventItemType.photo => 'Photo',
                  EventItemType.note => 'Note',
                  EventItemType.audio => 'Voice note',
                  EventItemType.pdf => 'PDF',
                }),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        fit: StackFit.expand,
                        children: [
                          // EXISTING IMAGE / PDF / NOTE / VOICE PREVIEW
                          record.item.type == EventItemType.note
                              ? SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: SelectableText(
                                    record.item.text,
                                    style: TextStyle(
                                      color: context.foregroundColor(
                                        Colors.white,
                                      ),
                                      fontSize: 16,
                                      height: 1.6,
                                    ),
                                  ),
                                )
                              : record.file == null
                              ? Center(
                                  child: Text(
                                    'This file is no longer available.',
                                    style: TextStyle(
                                      color: context.mutedColor(_muted),
                                    ),
                                  ),
                                )
                              : EventAttachmentPreview(
                                  key: ValueKey(
                                    '${record.item.id}:$previewVersion',
                                  ),
                                  file: record.file!,
                                  item: record.item,
                                  onEditPdf: () {},
                                  fillPreview:
                                      record.item.type == EventItemType.pdf,
                                  alignTop: true,
                                ),

                          FutureBuilder<Size?>(
                            future: photoSize,
                            builder: (context, snapshot) {
                              final size = snapshot.data;
                              final photoHeight = size == null
                                  ? null
                                  : applyBoxFit(
                                      BoxFit.contain,
                                      size,
                                      constraints.biggest,
                                    ).destination.height;
                              return Positioned(
                                left: 0,
                                right: 0,
                                top: photoHeight == null
                                    ? null
                                    : (photoHeight - 72).clamp(
                                        0.0,
                                        constraints.maxHeight,
                                      ),
                                bottom: photoHeight == null ? 16 : null,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.surfaceColor(
                                        Colors.black.withValues(alpha: 0.55),
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // CROSS ICON - DELETE
                                        IconButton(
                                          tooltip: 'Delete attachment',
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.redAccent,
                                            size: 25,
                                          ),
                                          onPressed: () async {
                                            final deleted =
                                                await _confirmDeleteImage(
                                                  record,
                                                );
                                            if (deleted && context.mounted)
                                              Navigator.of(context).pop();
                                          },
                                        ),

                                        const SizedBox(width: 14),

                                        // EDIT ICON
                                        IconButton(
                                          tooltip: 'Edit attachment',
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            color: context.foregroundColor(
                                              Colors.white,
                                            ),
                                            size: 23,
                                          ),
                                          onPressed: () async {
                                            final updated = await _editRecord(
                                              record,
                                            );
                                            if (updated == null ||
                                                !context.mounted)
                                              return;
                                            refresh(() {
                                              current = updated;
                                              previewVersion++;
                                              photoSize = _photoSize(updated);
                                            });
                                            if (mounted)
                                              setState(() {
                                                final index = _records.indexOf(
                                                  record,
                                                );
                                                if (index >= 0)
                                                  _records[index] = updated;
                                              });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    color: context.backgroundColor(_background),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _verticalDetail('Project Name', record.projectName),
                        const SizedBox(height: 10),
                        _verticalDetail('Area', record.item.area),
                        const SizedBox(height: 10),
                        _verticalDetail('Event', record.item.event),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _imageActionButton({
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.65),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: iconColor, size: 23),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  Widget _verticalDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              color: context.mutedColor(_muted),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.trim().isEmpty ? 'N/A' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.foregroundColor(Colors.white),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // void _open(EventDraftRecord record) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute<void>(
  //       builder: (context) => Scaffold(
  //         backgroundColor: _background,
  //         appBar: AppBar(
  //           backgroundColor: _background,
  //           foregroundColor: Colors.white,
  //           title: Text(switch (record.item.type) {
  //             EventItemType.photo => 'Photo',
  //             EventItemType.note => 'Note',
  //             EventItemType.audio => 'Voice note',
  //             EventItemType.pdf => 'PDF',
  //           }),
  //         ),
  //         body: SafeArea(
  //           child: record.item.type == EventItemType.note
  //               ? SingleChildScrollView(
  //                   padding: const EdgeInsets.all(24),
  //                   child: SelectableText(
  //                     record.item.text,
  //                     style: const TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 16,
  //                       height: 1.6,
  //                     ),
  //                   ),
  //                 )
  //               : record.file == null
  //               ? const Center(
  //                   child: Text(
  //                     'This file is no longer available.',
  //                     style: TextStyle(color: _muted),
  //                   ),
  //                 )
  //               : EventAttachmentPreview(
  //                   file: record.file!,
  //                   item: record.item,
  //                   onEditPdf: () {},
  //                   fillPreview: record.item.type == EventItemType.pdf,
  //                 ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final whiteTheme = WhiteAppTheme.isEnabled(context);
    final projects =
        _records
            .map((record) => record.projectName)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final groups = <DateTime, List<EventDraftRecord>>{};
    for (final record in _filtered) {
      groups.putIfAbsent(_day(record.date), () => []).add(record);
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go(AppRouter.dashboard);
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor(_background),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            color: _accent,
            backgroundColor: context.surfaceColor(_surface),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Records',
                                style: TextStyle(
                                  color: context.foregroundColor(Colors.white),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.2,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _showFilters,
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: Text(
                                _filterCount == 0
                                    ? 'Filters'
                                    : 'Filters · $_filterCount',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _filterCount == 0
                                    ? context.foregroundColor(Colors.white)
                                    : context.accentColor(_accent),
                                backgroundColor: context.surfaceColor(_surface),
                                side: BorderSide(
                                  color: context.borderColor(_border),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedProject ?? '',
                              dropdownColor: context.surfaceColor(_surface),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: context.mutedColor(_muted),
                                size: 20,
                              ),
                              style: TextStyle(
                                color: context.foregroundColor(Colors.white),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              selectedItemBuilder: (context) =>
                                  ['', ...projects]
                                      .map(
                                        (name) => Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.work_outline_rounded,
                                              size: 16,
                                              color: context.mutedColor(_muted),
                                            ),
                                            const SizedBox(width: 8),
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth:
                                                    MediaQuery.sizeOf(
                                                      context,
                                                    ).width -
                                                    100,
                                              ),
                                              child: Text(
                                                name.isEmpty
                                                    ? 'All projects'
                                                    : name,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: context
                                                      .foregroundColor(
                                                        Colors.white,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      )
                                      .toList(),
                              items: [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text(
                                    'All projects',
                                    style: TextStyle(
                                      color: context.foregroundColor(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                for (final project in projects)
                                  DropdownMenuItem(
                                    value: project,
                                    child: Text(
                                      project,
                                      style: TextStyle(
                                        color: context.foregroundColor(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                              onChanged: (value) => setState(() {
                                _selectedProject = value == '' ? null : value;
                                _selectedArea = null;
                                _selectedCategory = null;
                                _selectedEvent = null;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.surfaceColor(
                              const Color(0xFF092330),
                            ),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: context.borderColor(_border),
                            ),
                          ),
                          child: Row(
                            children: [
                              for (final entry in [
                                'All',
                                'Photos',
                                'Notes',
                                'Voice notes',
                              ].indexed)
                                Expanded(
                                  flex: entry.$1 == 3 ? 3 : 2,
                                  child: Semantics(
                                    selected: _selectedType == entry.$1,
                                    child: TextButton(
                                      onPressed: () => setState(
                                        () => _selectedType = entry.$1,
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                            _selectedType == entry.$1
                                            ? _accent
                                            : Colors.transparent,
                                        foregroundColor:
                                            _selectedType == entry.$1
                                            ? AppColors.primaryText
                                            : context.mutedColor(_muted),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 2,
                                        ),
                                        minimumSize: const Size(0, 44),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: Text(entry.$2, maxLines: 1),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                if (_loading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.accentColor(_accent),
                      ),
                    ),
                  )
                else if (_error != null || groups.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyState(),
                  )
                else
                  for (final entry in groups.entries) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _dayLabel(entry.key),
                                style: TextStyle(
                                  color: context.foregroundColor(Colors.white),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat(
                                entry.key.year == DateTime.now().year
                                    ? 'd MMM'
                                    : 'd MMM yyyy',
                              ).format(entry.key),
                              style: TextStyle(
                                color: context.mutedColor(_muted),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              whiteTheme &&
                                  MediaQuery.sizeOf(context).width < 480
                              ? 2
                              : 3,
                          mainAxisSpacing: whiteTheme ? 12 : 6,
                          crossAxisSpacing: whiteTheme ? 12 : 6,
                          childAspectRatio: whiteTheme ? 1.2 : 1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _recordCard(entry.value[index]),
                          childCount: entry.value.length,
                        ),
                      ),
                    ),
                  ],
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _error != null ? Icons.cloud_off_outlined : Icons.folder_open_rounded,
          size: 44,
          color: context.mutedColor(_muted),
        ),
        const SizedBox(height: 16),
        Text(
          _error != null
              ? 'Records unavailable'
              : _records.isEmpty
              ? 'Your records start here'
              : 'No matching records',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.foregroundColor(Colors.white),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _error ??
              (_records.isEmpty
                  ? 'Capture a photo, note or voice recording during a work session.'
                  : 'Try another project, record type or date filter.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.mutedColor(_muted),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        if (_error != null)
          TextButton(onPressed: _load, child: const Text('Try again')),
        if (_error == null && _records.isNotEmpty)
          TextButton(
            onPressed: () => setState(() {
              _selectedType = 0;
              _dateFilter = 0;
              _selectedArea = null;
              _selectedCategory = null;
              _selectedEvent = null;
              _oldestFirst = false;
              _selectedProject = null;
            }),
            child: const Text('Clear filters'),
          ),
      ],
    ),
  );

  Widget _recordCard(EventDraftRecord record) {
    final whiteTheme = WhiteAppTheme.isEnabled(context);
    final photo = record.item.type == EventItemType.photo;
    final voice = record.item.type == EventItemType.audio;
    final cardColor = whiteTheme
        ? (voice ? AppColors.primarySoft : WhiteAppTheme.surface)
        : (voice ? const Color(0xFF133D44) : _surface);
    final iconColor = whiteTheme
        ? WhiteAppTheme.accent
        : (voice ? const Color(0xFF9ED4D1) : _muted);
    final time = record.createdAt;
    final label = time == null ? '' : DateFormat('HH:mm').format(time);
    return Semantics(
      button: true,
      label: '${record.item.type.name} ${record.projectName} $label',
      child: Material(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(whiteTheme ? 16 : 10),
          side: BorderSide(color: context.borderColor(_border)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(record),
          child: photo
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      bottom: whiteTheme ? 32 : 0,
                      child: record.file != null
                          ? Image.file(
                              record.file!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.broken_image_outlined,
                                color: context.mutedColor(_muted),
                              ),
                            )
                          : Icon(
                              Icons.image_not_supported_outlined,
                              color: context.mutedColor(_muted),
                            ),
                    ),
                    if (whiteTheme)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ColoredBox(
                          color: WhiteAppTheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.photo_outlined,
                                  size: 14,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 5),
                                const Expanded(
                                  child: Text(
                                    'Photo',
                                    style: TextStyle(
                                      color: WhiteAppTheme.foreground,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: WhiteAppTheme.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else ...[
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : Padding(
                  padding: EdgeInsets.all(whiteTheme ? 12 : 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            voice
                                ? Icons.mic_none_rounded
                                : record.item.type == EventItemType.pdf
                                ? Icons.picture_as_pdf_outlined
                                : Icons.description_outlined,
                            color: iconColor,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              voice
                                  ? 'Voice'
                                  : record.item.type == EventItemType.pdf
                                  ? 'PDF'
                                  : 'Note',
                              maxLines: 1,
                              style: TextStyle(
                                color: context.mutedColor(_muted),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: voice
                            ? Center(
                                child: Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 40,
                                  color: context.accentColor(
                                    const Color(0xFF91CECA),
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) => Text(
                                  record.item.type == EventItemType.note
                                      ? record.item.text
                                      : record.item.name,
                                  maxLines: (constraints.maxHeight / 17)
                                      .floor()
                                      .clamp(1, 4),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.foregroundColor(
                                      Colors.white,
                                    ),
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: context.mutedColor(_muted),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
