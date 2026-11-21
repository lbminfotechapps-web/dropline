import 'package:flutter/material.dart';

class EventArea {
  EventArea({required this.id, required this.name, this.parentId});
  final String id;
  final String name;
  final String? parentId;
}

class EventChoice {
  const EventChoice(this.id, this.name);
  final String id;
  final String name;
}

class EventCategory {
  EventCategory(this.id, this.name, List<EventChoice> events)
      : events = List.unmodifiable(events);
  final String id;
  final String name;
  final List<EventChoice> events;
}

class EventHierarchySelection {
  EventHierarchySelection(List<EventArea> path, this.category, this.event)
      : path = List.unmodifiable(path);
  final List<EventArea> path;
  final EventCategory category;
  final EventChoice event;
  String get areaId => path.last.id;
  String get fullPath => path.map((a) => a.name).join(' > ');
  Map<String, dynamic> toJson() => {
    'area_id': areaId,
    'area_path_ids': path.map((a) => a.id).toList(),
    'category_id': category.id,
    'event_id': event.id,
  };
}

/// Replace or subclass this in-memory repository with your project setup API.
class EventHierarchyRepository {
  EventHierarchyRepository({required this.projectId,
    List<EventArea> areas = const [], List<EventCategory> categories = const [],
    this.areaLabels = const ['Main area', 'Floor', 'Apartment', 'Room'],
  }) : _areas = List.of(areas), _categories = List.of(categories) {
    if (areaLabels.isEmpty || areaLabels.length > 4) {
      throw ArgumentError('Use one to four area labels');
    }
  }
  final String projectId;
  final List<String> areaLabels;
  final List<EventArea> _areas;
  final List<EventCategory> _categories;
  int _sequence = 0;
  String _id() => 'local_${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
  String _normal(String s) => s.trim().toLowerCase();
  List<EventArea> children(String? parentId) =>
      _areas.where((a) => a.parentId == parentId).toList();
  List<EventCategory> get categories => List.unmodifiable(_categories);

  Future<EventArea> saveArea({required String? parentId, required String name}) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Enter area name');
    if (parentId != null && !_areas.any((a) => a.id == parentId)) {
      throw StateError('Parent area not found');
    }
    for (final area in children(parentId)) {
      if (_normal(area.name) == _normal(clean)) return area;
    }
    final area = EventArea(id: _id(), name: clean, parentId: parentId);
    _areas.add(area);
    return area;
  }

  Future<EventCategory> saveCategory(String name, String firstEvent) async {
    if (name.trim().isEmpty || firstEvent.trim().isEmpty) {
      throw ArgumentError('Both names are required');
    }
    if (_categories.any((c) => _normal(c.name) == _normal(name))) {
      throw StateError('Category already exists. Select it from the list.');
    }
    final category = EventCategory(_id(), name.trim(), [EventChoice(_id(), firstEvent.trim())]);
    _categories.add(category);
    return category;
  }

  factory EventHierarchyRepository.demo(String projectId) {
    final areas = <EventArea>[];
    for (final building in ['A', 'B', 'C']) {
      final b = EventArea(id: 'b$building', name: 'Building $building');
      areas.add(b);
      for (var f = 0; f < 4; f++) {
        final floor = EventArea(id: '${b.id}_f$f', parentId: b.id,
          name: ['Ground Floor', 'First Floor', 'Second Floor', 'Third Floor'][f]);
        areas.add(floor);
        for (final number in [1, 2, 3, 5]) {
          final apartment = EventArea(id: '${floor.id}_a$number', parentId: floor.id,
            name: 'Apartment ${f * 100 + number}');
          areas.add(apartment);
          for (final room in ['Kitchen', 'Bedroom', 'Bathroom']) {
            areas.add(EventArea(id: '${apartment.id}_$room', name: room, parentId: apartment.id));
          }
        }
      }
    }
    final samples = <String, List<String>>{
      'Quality': ['Workmanship issue', 'Damaged work', 'Inspection needed', 'Work accepted'],
      'Safety': ['Unsafe condition', 'Safety inspection'],
      'Progress': ['Work started', 'Work completed'],
      'Materials': ['Material received', 'Material shortage'],
      'Equipment': ['Equipment issue', 'Equipment inspection'],
    };
    var i = 0;
    final categories = samples.entries.map((entry) {
      final id = 'c${i++}';
      return EventCategory(id, entry.key, [for (var j = 0; j < entry.value.length; j++) EventChoice('${id}_$j', entry.value[j])]);
    }).toList();
    return EventHierarchyRepository(projectId: projectId, areas: areas, categories: categories);
  }
}

enum _Step { summary, area, newArea, category, event, newCategory }

class EventHierarchySheet extends StatefulWidget {
  const EventHierarchySheet({super.key, required this.projectName, required this.repository, this.initialSelection});
  final String projectName;
  final EventHierarchyRepository repository;
  final EventHierarchySelection? initialSelection;

  static Future<EventHierarchySelection?> show(BuildContext context, {
    required String projectName, required EventHierarchyRepository repository,
    EventHierarchySelection? initialSelection,
  }) => showModalBottomSheet<EventHierarchySelection>(
    context: context, isScrollControlled: true, useSafeArea: true,
    isDismissible: false, enableDrag: false, backgroundColor: Colors.transparent,
    builder: (_) => EventHierarchySheet(projectName: projectName, repository: repository, initialSelection: initialSelection),
  );

  @override
  State<EventHierarchySheet> createState() => _EventHierarchySheetState();
}

class _EventHierarchySheetState extends State<EventHierarchySheet> {
  static const _bg = Color(0xFF293D50);
  static const _surface = Color(0xFF203344);
  static const _accent = Color(0xFFBDF67C);
  static const _muted = Color(0xFFB5C4D1);
  static const _border = Color(0xFF607589);
  _Step _step = _Step.summary;
  List<EventArea> _selectedPath = [];
  final List<EventArea> _path = [];
  EventArea? _room;
  EventCategory? _category, _workingCategory;
  EventChoice? _event, _workingEvent;
  bool _creatingArea = false, _busy = false, _fromEvent = false;
  String? _error;
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _firstEvent = TextEditingController();
  EventHierarchyRepository get _repo => widget.repository;
  int get _depth => _path.length;
  String get _level => _repo.areaLabels[_depth];
  String? get _parentId => _path.isEmpty ? null : _path.last.id;
  List<EventArea> get _activeAreaPath => [
    ..._path,
    if (_room != null) _room!,
  ];
  String get _pathLabel => _activeAreaPath.map((a) => a.name).join(' > ');
  bool get _ready => _selectedPath.isNotEmpty && _category != null && _event != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSelection;
    if (initial != null) {
      _selectedPath = List.of(initial.path);
      _category = initial.category;
      _event = initial.event;
    }
  }
  @override
  void dispose() {
    _search.dispose(); _name.dispose(); _firstEvent.dispose(); super.dispose();
  }
  void _go(_Step step) {
    FocusScope.of(context).unfocus();
    _search.clear();
    _error = null;
    _step = step;
  }
  void _back() {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (_step == _Step.summary) { Navigator.of(context).pop(); return; }
    setState(() {
      switch (_step) {
        case _Step.area:
          if (_path.isNotEmpty) { _path.removeLast(); _room = null; _search.clear(); }
          else { _go(_Step.summary); }
          break;
        case _Step.newArea: _go(_Step.area); break;
        case _Step.category: _go(_fromEvent ? _Step.event : _Step.summary); break;
        case _Step.event: _go(_Step.category); _fromEvent = false; break;
        case _Step.newCategory: _go(_Step.summary); break;
        case _Step.summary: break;
      }
    });
  }
  void _openArea(bool create) => setState(() {
    _creatingArea = create; _path.clear(); _room = null; _go(_Step.area);
  });
  void _chooseArea(EventArea area) => setState(() {
    if (_depth == _repo.areaLabels.length - 1) { _room = area; }
    else { _path.add(area); _room = null; _search.clear(); }
  });
  void _useArea(List<EventArea> path) => setState(() {
    _selectedPath = List.of(path); _go(_Step.summary);
  });
  void _openCategory({bool events = false}) => setState(() {
    _workingCategory = _category; _workingEvent = _event; _fromEvent = false;
    _go(events && _category != null ? _Step.event : _Step.category);
  });
  void _chooseCategory(EventCategory category) => setState(() {
    if (_workingCategory?.id != category.id) _workingEvent = null;
    _workingCategory = category; _fromEvent = false; _go(_Step.event);
  });
  Future<void> _saveArea() async {
    if (_busy || _name.text.trim().isEmpty) return;
    setState(() { _busy = true; _error = null; });
    try {
      final area = await _repo.saveArea(parentId: _parentId, name: _name.text);
      if (!mounted) return;
      _useArea([..._path, area]);
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _saveCategory() async {
    if (_busy || _name.text.trim().isEmpty || _firstEvent.text.trim().isEmpty) return;
    setState(() { _busy = true; _error = null; });
    try {
      final category = await _repo.saveCategory(_name.text, _firstEvent.text);
      if (!mounted) return;
      setState(() { _category = category; _event = category.events.first; _go(_Step.summary); });
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  bool _matches(String value) => value.toLowerCase().contains(_search.text.trim().toLowerCase());
  String get _title => switch (_step) {
    _Step.summary => 'Add event', _Step.area => _creatingArea ? 'Add area' : 'Select area',
    _Step.newArea => 'New area', _Step.category => 'Choose category',
    _Step.event => 'Choose event', _Step.newCategory => 'New category',
  };

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return PopScope(
      canPop: !_busy && _step == _Step.summary,
      onPopInvokedWithResult: (didPop, _) { if (!didPop && !_busy) _back(); },
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Theme(
          data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _accent, surface: _bg)),
          child: Material(
            color: _bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(top: false, child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: (media.size.height - media.viewInsets.bottom - media.padding.top) * (media.viewInsets.bottom > 0 ? .93 : .65)),
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _muted, borderRadius: BorderRadius.circular(5)))),
                  Row(children: [
                    if (_step != _Step.summary) IconButton(onPressed: _busy ? null : _back, icon: const Icon(Icons.arrow_back)),
                    Expanded(child: Text(_title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    IconButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                  ]),
                  Flexible(child: SingleChildScrollView(key: ValueKey('$_step:$_depth'), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      ..._content(),
                      if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
                      if (_busy) const LinearProgressIndicator(),
                    ],
                  ))),
                  if (_footer() != null) ...[const SizedBox(height: 12), _footer()!],
                ],
              )),
            )),
          ),
        ),
      ),
    );
  }
  Widget _caption(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(text, style: const TextStyle(color: _muted, fontSize: 13)));
  Widget _breadcrumb(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 2),
    child: Text(value, style: const TextStyle(
      color: _accent, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4,
    )),
  );
  Widget _field(TextEditingController controller, String hint, {bool search = false}) => TextField(
    controller: controller, enabled: !_busy, onChanged: (_) => setState(() => _error = null),
    decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: _muted),
      prefixIcon: search ? const Icon(Icons.search, size: 20) : null,
      filled: true, fillColor: _surface, isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border))),
  );
  Widget _newButton(VoidCallback action) => OutlinedButton.icon(onPressed: _busy ? null : action,
    style: OutlinedButton.styleFrom(foregroundColor: _accent, side: const BorderSide(color: _accent)), icon: const Icon(Icons.add, size: 16), label: const Text('New'));
  Widget _dropdown(String label, VoidCallback? action) => OutlinedButton(onPressed: action,
    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: _surface, padding: const EdgeInsets.all(12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    child: Row(children: [Expanded(child: Text(label, overflow: TextOverflow.ellipsis)), const Icon(Icons.expand_more, size: 20)]));
  Widget _row(String name, VoidCallback action, {bool selected = false, bool next = false}) => Padding(
    padding: const EdgeInsets.only(top: 5), child: Material(color: selected ? const Color(0xFF365044) : _surface, borderRadius: BorderRadius.circular(9), child: ListTile(
      dense: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9), side: BorderSide(color: selected ? _accent : _border)),
      title: Text(name, style: TextStyle(color: selected ? _accent : Colors.white)),
      trailing: Icon(selected ? Icons.check : next ? Icons.chevron_right : Icons.radio_button_unchecked, color: selected ? _accent : _muted, size: 19),
      onTap: _busy ? null : action,
    )));
  Widget _empty() => const Padding(padding: EdgeInsets.all(16), child: Text('No matching items', textAlign: TextAlign.center));
  List<Widget> _content() {
    switch (_step) {
      case _Step.summary:
        return [
          _caption('Area'), Row(children: [Expanded(child: _dropdown(_selectedPath.isEmpty ? 'Select area' : _selectedPath.reversed.take(2).toList().reversed.map((a) => a.name).join(' / '), () => _openArea(false))), const SizedBox(width: 8), _newButton(() => _openArea(true))]),
          if (_selectedPath.isNotEmpty) _caption(_selectedPath.map((a) => a.name).join(' > ')),
          _caption('Category'), Row(children: [Expanded(child: _dropdown(_category?.name ?? 'Select category', () => _openCategory())), const SizedBox(width: 8), _newButton(() => setState(() { _name.clear(); _firstEvent.clear(); _go(_Step.newCategory); }))]),
          _caption('Event'), _dropdown(_category == null ? 'Select category first' : _event?.name ?? 'Select event', _category == null ? null : () => _openCategory(events: true)),
        ];
      case _Step.area:
        final areas = _repo.children(_parentId).where((a) => _matches(a.name)).toList();
        final last = _depth == _repo.areaLabels.length - 1;
        return [
          if (_activeAreaPath.isNotEmpty) _breadcrumb(_pathLabel),
          Row(children: [Expanded(child: _caption(_level)), if (_creatingArea) _newButton(() => setState(() { _name.clear(); _go(_Step.newArea); }))]),
          _field(_search, 'Search ${_level.toLowerCase()}', search: true),
          for (final area in areas) _row(area.name, () => _chooseArea(area), selected: _room?.id == area.id, next: !last),
          if (areas.isEmpty) _empty(),
        ];
      case _Step.newArea:
        return [
          _breadcrumb([
            ..._path.map((area) => area.name),
            _name.text.trim().isEmpty ? 'New $_level' : _name.text.trim(),
          ].join(' > ')),
          _caption('$_level name'),
          _field(_name, 'Enter name'),
        ];
      case _Step.category:
        final categories = _repo.categories.where((c) => _matches(c.name)).toList();
        return [if (_selectedPath.isNotEmpty) _caption(_selectedPath.map((a) => a.name).join(' > ')),
          _field(_search, 'Search categories', search: true),
          for (final category in categories) _row(category.name, () => _chooseCategory(category), selected: _workingCategory?.id == category.id, next: true),
          if (categories.isEmpty) _empty(),
        ];
      case _Step.event:
        final events = (_workingCategory?.events ?? <EventChoice>[]).where((e) => _matches(e.name)).toList();
        return [Row(children: [Expanded(child: Text(_workingCategory?.name ?? '')), TextButton(onPressed: () => setState(() { _fromEvent = true; _go(_Step.category); }), child: const Text('Change'))]),
          _field(_search, 'Search ${_workingCategory?.events.length ?? 0} events', search: true),
          for (final event in events) _row(event.name, () => setState(() => _workingEvent = event), selected: _workingEvent?.id == event.id),
          if (events.isEmpty) _empty(),
        ];
      case _Step.newCategory:
        return [_caption('Category name'), _field(_name, 'Enter category name'), const SizedBox(height: 8), _caption('First event'), _field(_firstEvent, 'Enter first event name')];
    }
  }
  Widget _primary(String label, VoidCallback? action) => FilledButton(onPressed: _busy ? null : action,
    style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF172717), minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)));
  Widget? _footer() {
    switch (_step) {
      case _Step.summary:
        return _primary('Add event', !_ready ? null : () => Navigator.of(context).pop(EventHierarchySelection(_selectedPath, _category!, _event!)));
      case _Step.area:
        final path = _activeAreaPath;
        if (path.isEmpty) return null;
        return _primary('Use area', () => _useArea(path));
      case _Step.newArea: return _primary('Save area', _name.text.trim().isEmpty ? null : _saveArea);
      case _Step.category: return null;
      case _Step.event: return _primary('Use event', _workingCategory == null || _workingEvent == null ? null : () => setState(() { _category = _workingCategory; _event = _workingEvent; _go(_Step.summary); }));
      case _Step.newCategory: return _primary('Save category', _name.text.trim().isEmpty || _firstEvent.text.trim().isEmpty ? null : _saveCategory);
    }
  }
}
