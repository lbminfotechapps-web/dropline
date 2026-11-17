import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:intl/intl.dart';

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
  static const _accent = Color(0xFFB5FF65);
  final _store = EventDraftStore();
  List<EventDraftRecord> _records = [];
  bool _loading = true;
  String? _error;
  String? _selectedProject;
  int _selectedType = 0;
  int _dateFilter = 0;

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

  List<EventDraftRecord> get _filtered {
    final today = _day(DateTime.now());
    final types = [
      null,
      EventItemType.photo,
      EventItemType.note,
      EventItemType.audio,
    ];
    return _records.where((record) {
      if (_selectedProject != null && record.projectName != _selectedProject) {
        return false;
      }
      if (types[_selectedType] != null &&
          record.item.type != types[_selectedType]) {
        return false;
      }
      final date = _day(record.date);
      return switch (_dateFilter) {
        1 => date == today,
        2 => date == DateTime(today.year, today.month, today.day - 1),
        3 =>
          !date.isBefore(DateTime(today.year, today.month, today.day - 6)) &&
              !date.isAfter(today),
        _ => true,
      };
    }).toList()..sort((a, b) {
      final byDay = b.date.compareTo(a.date);
      return byDay != 0
          ? byDay
          : (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date);
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
    var selected = _dateFilter;
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Filter records',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Date',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in [
                      'All dates',
                      'Today',
                      'Yesterday',
                      'Last 7 days',
                    ].indexed)
                      ChoiceChip(
                        label: Text(entry.$2),
                        selected: selected == entry.$1,
                        selectedColor: _accent,
                        backgroundColor: _background,
                        labelStyle: TextStyle(
                          color: selected == entry.$1
                              ? _background
                              : Colors.white,
                        ),
                        onSelected: (_) => update(() => selected = entry.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _background,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Apply filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && result != null) setState(() => _dateFilter = result);
  }

  void _open(EventDraftRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            backgroundColor: _background,
            foregroundColor: Colors.white,
            title: Text(switch (record.item.type) {
              EventItemType.photo => 'Photo',
              EventItemType.note => 'Note',
              EventItemType.audio => 'Voice note',
              EventItemType.pdf => 'PDF',
            }),
          ),
          body: SafeArea(
            child: record.item.type == EventItemType.note
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: SelectableText(
                      record.item.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  )
                : record.file == null
                ? const Center(
                    child: Text(
                      'This file is no longer available.',
                      style: TextStyle(color: _muted),
                    ),
                  )
                : EventAttachmentPreview(
                    file: record.file!,
                    item: record.item,
                    onEditPdf: () {},
                    fillPreview: record.item.type == EventItemType.pdf,
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: _background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            color: _accent,
            backgroundColor: _surface,
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
                            const Expanded(
                              child: Text(
                                'Records',
                                style: TextStyle(
                                  color: Colors.white,
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
                                _dateFilter == 0 ? 'Filters' : 'Filters · 1',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _dateFilter == 0
                                    ? Colors.white
                                    : _accent,
                                backgroundColor: _surface,
                                side: const BorderSide(color: _border),
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
                              dropdownColor: _surface,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _muted,
                                size: 20,
                              ),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              selectedItemBuilder: (context) =>
                                  ['', ...projects]
                                      .map(
                                        (name) => Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.work_outline_rounded,
                                              size: 16,
                                              color: _muted,
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
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      )
                                      .toList(),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('All projects'),
                                ),
                                for (final project in projects)
                                  DropdownMenuItem(
                                    value: project,
                                    child: Text(project),
                                  ),
                              ],
                              onChanged: (value) => setState(
                                () => _selectedProject = value == ''
                                    ? null
                                    : value,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF092330),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: _border),
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
                                            ? _background
                                            : _muted,
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
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: _accent),
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
                                style: const TextStyle(
                                  color: Colors.white,
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
                              style: const TextStyle(
                                color: _muted,
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
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
          color: _muted,
        ),
        const SizedBox(height: 16),
        Text(
          _error != null
              ? 'Records unavailable'
              : _records.isEmpty
              ? 'Your records start here'
              : 'No matching records',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
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
          style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
        ),
        if (_error != null)
          TextButton(onPressed: _load, child: const Text('Try again')),
        if (_error == null && _records.isNotEmpty)
          TextButton(
            onPressed: () => setState(() {
              _selectedType = 0;
              _dateFilter = 0;
              _selectedProject = null;
            }),
            child: const Text('Clear filters'),
          ),
      ],
    ),
  );

  Widget _recordCard(EventDraftRecord record) {
    final photo = record.item.type == EventItemType.photo;
    final voice = record.item.type == EventItemType.audio;
    final time = record.createdAt;
    final label = time == null ? '' : DateFormat('HH:mm').format(time);
    return Semantics(
      button: true,
      label: '${record.item.type.name} ${record.projectName} $label',
      child: Material(
        color: voice ? const Color(0xFF133D44) : _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(record),
          child: photo
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    if (record.file != null)
                      Image.file(
                        record.file!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: _muted,
                        ),
                      )
                    else
                      const Icon(
                        Icons.image_not_supported_outlined,
                        color: _muted,
                      ),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(9),
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
                            color: voice ? const Color(0xFF9ED4D1) : _muted,
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
                              style: const TextStyle(
                                color: _muted,
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
                            ? const Center(
                                child: Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 40,
                                  color: Color(0xFF91CECA),
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
                                  style: const TextStyle(
                                    color: Colors.white,
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
                          style: const TextStyle(
                            color: _muted,
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
