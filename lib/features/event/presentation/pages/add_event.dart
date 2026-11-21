import 'dart:async';
import 'dart:io';
import 'package:dropline/features/event/domain/entities/event_draft_scope.dart';

import 'package:dropline/features/event/presentation/pages/event_area.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/pdf_editor_page.dart';
import '../../data/repositories/event_draft_store.dart';
import '../widgets/event_attachment_preview.dart';
import 'photo_editor_page.dart';
import 'event_camera_page.dart';
import 'package:dropline/core/api_constant/dio_client.dart';
import 'package:dropline/features/event/data/datasources/time_slot_remote_datasource.dart';

import 'package:dropline/core/router/app_router.dart';
import 'package:go_router/go_router.dart';

import '../widgets/audio_recorder_dialog.dart';

import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/theme/app_text_styles.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({
    super.key,
    required this.projectId,
    required this.projectName,
    this.onCamera,
    this.onRecordAudio,
    this.timeSlotDataSource,
    this.draftStore,
    this.hierarchyRepository,
    this.onApplyEvent,
  });
  final String projectId;
  final String projectName;

  final VoidCallback? onCamera;
  final VoidCallback? onRecordAudio;

  final TimeSlotRemoteDataSource? timeSlotDataSource;
  final EventDraftStore? draftStore;
  final EventHierarchyRepository? hierarchyRepository;
  final Future<void> Function(
    EventDraftScope scope,
    EventHierarchySelection selection,
  )?
  onApplyEvent;

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  static const _canvas = AppColors.background;
  static const _ink = AppColors.textPrimary;
  static const _muted = AppColors.textSecondary;
  static const _line = AppColors.border;
  static const _green = AppColors.primary;
  static const _backButtonSize = 44.0;
  static const _actionSpacing = 8.0;
  static const _actionBorderRadius = BorderRadius.all(Radius.circular(20));

  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  late final EventDraftStore _store;
  late final EventHierarchyRepository _hierarchyRepository;
  bool _eventFlowOpen = false;
  bool _cameraOpen = false;
  final _cameraActions = EventCameraActions();
  EventHierarchySelection? _pendingHierarchy;
  final _draftDate = DateTime.now();
  List<EventDraftItem> _items = [];
  bool _attachmentValidationAttempted = false;
  final Set<String> _selectedItemIds = {};

  bool get _hasAttachment => _items.any(
    (item) =>
        _selectedItemIds.contains(item.id) &&
        (item.type == EventItemType.photo ||
            item.type == EventItemType.pdf ||
            item.type == EventItemType.audio ||
            (item.type == EventItemType.note && item.text.trim().isNotEmpty)),
  );

  bool get _attachmentInvalid =>
      _attachmentValidationAttempted && !_hasAttachment;

  String _userId = 'local';
  String? _punchProjectName;
  bool _loadingDraft = true;
  String? _draftError;
  bool _saveFailed = false;
  int _pendingSaves = 0;
  int _draftVersion = 0;
  File? _previewFile;
  int _previewVersion = 0;

  String get _scope => EventDraftStore.scope(
    userId: _userId,
    project: widget.projectName,
    date: _draftDate,
    slotId: _timeSlots[_selectedTime].id,
  );

  EventDraftItem? get _selectedItem =>
      _selectedCard >= 0 && _selectedCard < _items.length
      ? _items[_selectedCard]
      : null;
  bool get _canEdit =>
      !_eventFlowOpen &&
      !_loadingDraft &&
      !_picking &&
      _draftError == null &&
      _timeSlots.isNotEmpty;
  int _selectedTime = 0;
  List<TimeSlot> _timeSlots = [];
  final Set<String> _slotsWithData = {};
  bool _loadingTimeSlots = true;
  bool _timeSlotsFailed = false;
  int _selectedCard = -1;
  bool _picking = false;

  String _timeLabel(int index) {
    return _timeSlots.isEmpty ? '--:--' : _timeSlots[index].time;
  }

  @override
  void initState() {
    super.initState();
    _store = widget.draftStore ?? EventDraftStore();
    _hierarchyRepository =
        widget.hierarchyRepository ??
        EventHierarchyRepository.demo(widget.projectId);
    unawaited(_loadPunchProjectName());
    _initialise();
  }

  EventDraftScope get _eventDraftScope {
    if (_timeSlots.isEmpty) {
      throw StateError('No time slot selected');
    }

    return EventDraftScope(
      userId: _userId,
      projectId: widget.projectId,
      date: _draftDate,
      timeSlotId: _timeSlots[_selectedTime].id,
      selectedItemIds: Set<String>.unmodifiable(_selectedItemIds),
    );
  }

  Future<void> _loadPunchProjectName() async {
    if (!sl.isRegistered<SecureStorage>()) return;
    try {
      final punches = await sl<SecureStorage>().readPunchInResult();
      if (!mounted || punches.isEmpty) return;
      final name = punches.first.projectName.trim();
      if (name.isNotEmpty) {
        setState(() => _punchProjectName = name);
      }
    } catch (_) {
      // Keep the supplied project name if the saved punch cannot be read.
    }
  }

  Future<void> _initialise() async {
    try {
      if (sl.isRegistered<SecureStorage>()) {
        final login = await sl<SecureStorage>().readLoginResponse();
        if (!mounted) return;
        if (login != null && login.result.isNotEmpty) {
          _userId = login.result.first.userId;
        }
      }
      await _recoverCamera();
      if (mounted) await _loadTimeSlots();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingTimeSlots = false;
          _loadingDraft = false;
          _draftError =
              'Unable to load saved user details. Reopen this screen to retry.';
        });
      }
    }
  }

  Future<void> _loadTimeSlots() async {
    setState(() {
      _loadingTimeSlots = true;
      _timeSlotsFailed = false;
    });
    try {
      List<TimeSlot> slots;
      try {
        slots =
            await (widget.timeSlotDataSource ??
                    TimeSlotRemoteDataSource(DioClient().client))
                .getTimeSlots();
        unawaited(_store.cacheSlots(slots).catchError((Object _) {}));
      } catch (_) {
        slots = await _store.cachedSlots();
        if (slots.isEmpty) rethrow;
      }
      if (!mounted) return;
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;
      var selected = 0;
      var latestMinutes = -1;
      for (var index = 0; index < slots.length; index++) {
        final minutes = _slotMinutes(slots[index].time);
        if (minutes == null) continue;
        if (minutes <= currentMinutes && minutes > latestMinutes) {
          selected = index;
          latestMinutes = minutes;
        }
      }
      setState(() {
        _timeSlots = slots;
        _selectedTime = selected;
        _loadingTimeSlots = false;
      });
      if (slots.isNotEmpty) {
        await _loadDraft();
        unawaited(_loadSlotIndicators());
      } else {
        setState(() => _loadingDraft = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTimeSlots = false;
        _timeSlotsFailed = true;
        _loadingDraft = false;
      });
    }
  }

  int? _slotMinutes(String time) {
    final match = RegExp(
      r'^\s*(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?\s*$',
      caseSensitive: false,
    ).firstMatch(time);
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)?.toUpperCase();
    if (minute > 59 ||
        hour > (period == null ? 23 : 12) ||
        (period != null && hour == 0)) {
      return null;
    }
    if (period != null) hour = hour % 12 + (period == 'PM' ? 12 : 0);
    return hour * 60 + minute;
  }

  Future<void> _loadSlotIndicators() async {
    for (final slot in _timeSlots) {
      final scope = EventDraftStore.scope(
        userId: _userId,
        project: widget.projectName,
        date: _draftDate,
        slotId: slot.id,
      );
      try {
        final items = await _store.load(scope);
        if (!mounted) return;
        // The selected slot may have changed while its saved draft was loading.
        if (slot.id == _timeSlots[_selectedTime].id) continue;
        setState(() {
          if (items.isNotEmpty) {
            _slotsWithData.add(slot.id);
          } else {
            _slotsWithData.remove(slot.id);
          }
        });
      } catch (_) {
        // A failed indicator read must not prevent editing other slots.
      }
    }
  }

  Future<void> _loadDraft() async {
    final scope = _scope;
    final version = ++_draftVersion;
    setState(() {
      _loadingDraft = true;
      _draftError = null;
      _previewFile = null;
      _noteController.clear();
    });
    try {
      final items = await _store.load(scope);
      if (!mounted || version != _draftVersion) return;
      setState(() {
        if (items.isNotEmpty) {
          _slotsWithData.add(_timeSlots[_selectedTime].id);
        } else {
          _slotsWithData.remove(_timeSlots[_selectedTime].id);
        }
        _items = items;
        _selectedItemIds.removeWhere(
          (id) => !items.any((item) => item.id == id),
        );
        _attachmentValidationAttempted = false;
        _selectedCard = items.isEmpty ? -1 : 0;
        _loadingDraft = false;
      });
      if (items.isNotEmpty) await _selectItem(0);
    } catch (_) {
      if (!mounted || version != _draftVersion) return;
      setState(() {
        _loadingDraft = false;
        _draftError = 'Unable to read this draft. Tap to retry.';
      });
    }
  }

  Future<bool> _saveDraft() async {
    if (_timeSlots.isEmpty) return false;
    final scope = _scope;
    final slotId = _timeSlots[_selectedTime].id;
    final items = List<EventDraftItem>.of(_items);
    final version = ++_saveVersion;
    setState(() => _pendingSaves++);
    try {
      await _store.save(scope, items);
      if (mounted) {
        setState(() {
          if (items.isNotEmpty) {
            _slotsWithData.add(slotId);
          } else {
            _slotsWithData.remove(slotId);
          }
        });
      }
      if (mounted && version == _saveVersion) {
        setState(() => _saveFailed = false);
      }
      return true;
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
      return false;
    } finally {
      if (mounted) setState(() => _pendingSaves--);
    }
  }

  int _saveVersion = 0;

  Future<void> _removeSelectedItem() async {
    final item = _selectedItem;
    if (item == null || !_canEdit || _pendingSaves > 0 || _saveFailed) return;
    setState(() {
      _items.removeWhere((entry) => entry.id == item.id);
      _selectedItemIds.remove(item.id);
      _selectedCard = -1;
      _previewFile = null;
      _previewVersion++;
    });
    await _saveDraft();
  }

  Future<void> _selectTime(int index) async {
    if (!_canEdit || _saveFailed || _pendingSaves > 0) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedTime = index;
      _pendingHierarchy = null;
    });
    await _loadDraft();
  }

  Future<void> _selectItem(int index) async {
    if (!_canEdit) return;
    final item = _items[index];
    final scope = _scope;
    final version = ++_previewVersion;
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedCard = index;
      _previewFile = null;
      _noteController.text = item.type == EventItemType.note ? item.text : '';
    });
    if (item.type != EventItemType.note) {
      try {
        final file = await _store.file(scope, item);
        if (!mounted || version != _previewVersion || scope != _scope) return;
        setState(() => _previewFile = file);
      } catch (_) {
        if (mounted && version == _previewVersion) {
          setState(
            () => _draftError = 'Unable to open this attachment. Tap to retry.',
          );
        }
      }
    }
  }

  void _startNote() {
    if (_selectedItem?.type != EventItemType.note ||
        _noteController.text.isNotEmpty) {
      _newNote();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedItem?.type == EventItemType.note) {
        _noteFocus.requestFocus();
      }
    });
  }

  void _newNote() {
    if (!_canEdit) return;
    FocusScope.of(context).unfocus();
    final item = EventDraftItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: EventItemType.note,
      name:
          'Note ${_items.where((e) => e.type == EventItemType.note).length + 1}',
    );
    setState(() {
      _items.add(item);
      _selectedCard = _items.length - 1;
      _previewFile = null;
      _noteController.clear();
    });
    unawaited(_saveDraft());
  }

  void _noteChanged(String value) {
    if (!_canEdit) return;
    if (_selectedItem?.type != EventItemType.note) {
      setState(() {
        _items.add(
          EventDraftItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            type: EventItemType.note,
            name:
                'Note ${_items.where((item) => item.type == EventItemType.note).length + 1}',
            text: value,
          ),
        );
        _selectedCard = _items.length - 1;
      });
    } else {
      setState(() => _items[_selectedCard] = _selectedItem!.withText(value));
    }
    unawaited(_saveDraft());
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addFiles(List<XFile> files, EventItemType type) async {
    final scope = _scope;
    for (final source in files) {
      final item = await _store.importFile(scope, source, type);
      if (!mounted) return;
      setState(() {
        _items.add(item);
        _selectedCard = _items.length - 1;
        _noteController.clear();
      });
      final file = await _store.file(scope, item);
      if (mounted) setState(() => _previewFile = file);
      await _saveDraft();
    }
  }

  Future<void> _pickPdf() async {
    if (!_canEdit) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (!mounted) return;
      await _addFiles(
        result.map((file) => file.xFile).toList(),
        EventItemType.pdf,
      );
    } catch (_) {
      _message('Unable to attach files. Please try again.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _recoverCamera() async {
    if (!Platform.isAndroid) return;
    try {
      final scope = await _store.cameraScope();
      if (scope == null) return;
      final response = await ImagePicker().retrieveLostData();
      if (response.files != null) {
        final items = await _store.load(scope);
        for (final file in response.files!) {
          items.add(await _store.importFile(scope, file, EventItemType.photo));
        }
        await _store.save(scope, items);
      }
      await _store.rememberCameraScope(null);
    } catch (_) {
      _message('Unable to recover the last camera photo.');
    }
  }

  Future<void> _attachCameraPhotos(List<XFile> photos) async {
    final scope = _scope;
    final added = <EventDraftItem>[];
    for (final photo in photos) {
      added.add(await _store.importFile(scope, photo, EventItemType.photo));
    }
    final updated = [..._items, ...added];
    final preview = await _store.file(scope, added.last);
    await _store.save(scope, updated);
    if (!mounted) return;
    setState(() {
      _items = updated;
      _selectedCard = updated.length - 1;
      _previewFile = preview;
      _previewVersion++;
      _noteController.clear();
      _slotsWithData.add(_timeSlots[_selectedTime].id);
      _saveFailed = false;
    });
  }

  Future<void> _takePhoto() async {
    if (!_canEdit) return;
    FocusScope.of(context).unfocus();
    setState(() => _cameraOpen = true);
  }

  void _closeCamera() {
    setState(() => _cameraOpen = false);
  }

  Future<void> _attachInlinePhoto(List<XFile> photos) async {
    setState(() => _picking = true);
    try {
      await _attachCameraPhotos(photos);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _openRecorder() async {
    if (!_canEdit) return;
    FocusScope.of(context).unfocus();
    setState(() => _picking = true);
    try {
      final path = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AudioRecorderDialog(),
      );
      if (path != null && mounted) {
        await _addFiles([XFile(path)], EventItemType.audio);
      }
    } catch (_) {
      _message('Unable to attach recording. Please try again.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _editPhoto() async {
    final item = _selectedItem;
    final file = _previewFile;
    if (!_canEdit || item == null || file == null) return;
    final scope = _scope;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PhotoEditorPage(
          file: file,
          onSave: (bytes) => _store.replaceFile(scope, item, bytes),
        ),
      ),
    );
    if (saved == true) {
      await FileImage(file).evict();
      if (!mounted) return;
      setState(() => _previewVersion++);
      _message('Photo changes saved on this device.');
    }
  }

  Future<void> _editPdf() async {
    final item = _selectedItem;
    final file = _previewFile;
    if (!_canEdit || item == null || file == null) return;
    final scope = _scope;
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PdfEditorPage(
            initialBytes: bytes,
            fileName: item.name,
            onSave: (bytes) => _store.replaceFile(scope, item, bytes),
          ),
        ),
      );
      if (saved == true && mounted) {
        setState(() => _previewVersion++);
        _message('PDF changes saved on this device.');
      }
    } catch (_) {
      _message('Unable to open PDF. Please try again.');
    }
  }

  Future<void> _completeEvent() async {
    if (_eventFlowOpen) return;

    FocusScope.of(context).unfocus();

    setState(() => _attachmentValidationAttempted = true);
    if (_attachmentInvalid) {
      return;
    }

    debugPrint('========== ADD EVENT CLICKED ==========');

    setState(() {
      _eventFlowOpen = true;
    });

    bool reloadDraft = false;

    try {
      final selection = await EventHierarchySheet.show(
        context,
        projectName: widget.projectName,
        repository: _hierarchyRepository,
        initialSelection: _pendingHierarchy,
      );

      if (!mounted || selection == null) return;

      _pendingHierarchy = selection;

      debugPrint('========== SELECTED EVENT ==========');
      debugPrint('Area ID: ${selection.areaId}');
      debugPrint('Area Path: ${selection.fullPath}');
      debugPrint('Category: ${selection.category.name}');
      debugPrint('Category ID: ${selection.category.id}');
      debugPrint('Event: ${selection.event.name}');
      debugPrint('Event ID: ${selection.event.id}');
      debugPrint('Payload: ${selection.toJson()}');

      if (_userId.isEmpty || _userId == 'local') {
        _message('User ID not found.');
        return;
      }

      if (widget.projectId.trim().isEmpty) {
        _message('Project ID not found.');
        return;
      }

      if (_timeSlots.isEmpty) {
        _message('Time slot not found.');
        return;
      }

      final scope = _eventDraftScope;

      final saved = await _saveDraft();

      if (!mounted) return;

      if (!saved) {
        _message('Unable to save draft.');
        return;
      }

      final apply = widget.onApplyEvent;

      if (apply != null) {
        await apply(scope, selection);

        if (!mounted) return;

        _pendingHierarchy = null;

        reloadDraft = true;

        _message('Event added successfully.');
      } else {
        _message('Event selected successfully.');

        debugPrint('Event submission API not connected.');
      }
    } catch (e, stackTrace) {
      debugPrint('ADD EVENT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _message('Unable to add event: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _eventFlowOpen = false;
        });

        if (reloadDraft) {
          await _loadDraft();
        }
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final noteSelected =
        !_cameraOpen && _selectedItem?.type == EventItemType.note;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
        systemNavigationBarColor: _canvas,
      ),
      child: PopScope(
        canPop:
            !_eventFlowOpen && _pendingSaves == 0 && !_picking && !_saveFailed,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _message(
              _saveFailed
                  ? 'Your changes are not saved. Tap Retry before leaving.'
                  : 'Please wait while your changes are saved.',
            );
          }
        },
        child: Scaffold(
          // backgroundColor: _canvas,jy
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!keyboardVisible) ...[
                    Row(
                      children: [
                        // IconButton(
                        //   tooltip: 'Punch out',
                        //   onPressed: () => context.push(AppRouter.punchOut),
                        //   color: _muted,
                        //   icon: const Icon(Icons.apartment_outlined, size: 20),
                        // ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Center(
                                  child: Text(
                                    _punchProjectName ?? widget.projectName,
                                    style: AppTextStyles.titleSmall,
                                  ),
                                ),
                              ),
                              // _buildDateHeader(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!noteSelected)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: _actionBorderRadius,
                            ),
                            child: _cameraOpen
                                ? EventCameraPage(
                                    onConfirm: _attachInlinePhoto,
                                    onClose: _closeCamera,
                                    inline: true,
                                    actions: _cameraActions,
                                  )
                                : _selectedItem == null
                                ? _buildSitePrompt()
                                : _buildPreviewCard(),
                          ),
                        ),
                      ),
                    if (noteSelected && _draftError != null) _buildSitePrompt(),
                  ],
                  Flexible(
                    key: const ValueKey('event-composer-area'),
                    flex: noteSelected ? 1 : 0,
                    fit: FlexFit.tight,
                    child: _buildComposer(keyboardVisible, noteSelected),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSitePrompt() {
    if (_draftError != null) {
      return Center(
        child: TextButton(
          onPressed: _timeSlots.isEmpty ? null : _loadDraft,
          child: Text(_draftError!, textAlign: TextAlign.center),
        ),
      );
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'What’s happening on site?',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge,
        ),
      ),
    );
  }

  Widget _buildComposer(bool editingNote, bool noteSelected) {
    return Column(
      key: const ValueKey('event-composer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (noteSelected) Expanded(child: _buildNoteField()),
        if (editingNote)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _noteFocus.unfocus,
              child: const Text('Done'),
            ),
          )
        else ...[
          if (_items.isNotEmpty) _buildEventItems(),
          _buildTimeline(),
          if (_attachmentInvalid)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'Add and select at least one image, PDF, note or audio.',
                style: AppTextStyles.inputError,
              ),
            ),
          _buildBottomTools(),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox.square(
                dimension: _backButtonSize,
                child: IgnorePointer(
                  ignoring: _picking,
                  child: BackButton(
                    color: _ink,
                    onPressed: () => context.go(AppRouter.dashboard),
                  ),
                ),
              ),
              const SizedBox(width: _actionSpacing),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FilledButton(
                    onPressed:
                        _eventFlowOpen ||
                            _picking ||
                            _loadingDraft ||
                            _pendingSaves > 0
                        ? null
                        : () async {
                            debugPrint('Add Event Button Clicked');

                            if (_saveFailed) {
                              await _saveDraft();
                            } else {
                              if (_cameraOpen) _closeCamera();
                              await _completeEvent();
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: AppColors.primaryText,
                      shape: const RoundedRectangleBorder(
                        borderRadius: _actionBorderRadius,
                      ),
                    ),
                    child: Text(_saveFailed ? 'Retry' : 'Add Event'),
                  ),
                  //  FilledButton(
                  //   onPressed: !_canEdit || _pendingSaves > 0
                  //       ? null
                  //       : _saveFailed
                  //       ? _saveDraft
                  //       : _completeEvent,
                  //   style: FilledButton.styleFrom(
                  //     backgroundColor: _green,
                  //     foregroundColor: Colors.white,
                  //     shape: const RoundedRectangleBorder(
                  //       borderRadius: _actionBorderRadius,
                  //     ),
                  //   ),
                  //   child: Text(_saveFailed ? 'Retry' : 'Add Event'),
                  // ),
                ),
              ),
              const SizedBox(width: _backButtonSize + _actionSpacing),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTimeline() {
    if (_timeSlots.isEmpty) return const SizedBox.shrink();
    final count = _timeSlots.length.clamp(1, 5);
    final start = (_selectedTime - 2).clamp(0, _timeSlots.length - count);
    final enabled = _canEdit && !_saveFailed && _pendingSaves == 0;
    return Row(
      children: [
        for (var index = start; index < start + count; index++)
          Expanded(
            child: Semantics(
              selected: index == _selectedTime,
              child: TextButton(
                onPressed: enabled && index != _selectedTime
                    ? () {
                        if (_cameraOpen) _closeCamera();
                        _selectTime(index);
                      }
                    : null,
                style: TextButton.styleFrom(
                  backgroundColor: index == _selectedTime ? _green : null,
                  foregroundColor: _muted,
                  disabledForegroundColor: index == _selectedTime
                      ? AppColors.primaryText
                      : _muted,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: Text(
                  _timeLabel(index),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomTools() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tool(
              'PDF',
              const Icon(Icons.picture_as_pdf_outlined, size: 19),
              _canEdit
                  ? () {
                      if (_cameraOpen) _closeCamera();
                      _pickPdf();
                    }
                  : null,
            ),
          ),
          Expanded(
            child: _tool(
              'Photo',
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _canEdit || _cameraOpen ? _ink : _line,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.circle,
                  size: 55,
                  color: _canEdit || _cameraOpen ? _ink : _line,
                ),
              ),
              _cameraOpen
                  ? () => _cameraActions.capture?.call()
                  : _canEdit
                  ? widget.onCamera ?? _takePhoto
                  : null,
              tooltip: 'Take a photo',
            ),
          ),
          Expanded(
            child: PopupMenuButton<bool>(
              tooltip: 'Note & voice',
              color: AppColors.surface,
              enabled: _canEdit,
              onSelected: (writeNote) {
                if (_cameraOpen) _closeCamera();
                if (writeNote) {
                  _startNote();
                } else {
                  (widget.onRecordAudio ?? _openRecorder)();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: true,
                  child: Text('Write note', style: AppTextStyles.bodyMedium),
                ),
                PopupMenuItem(
                  value: false,
                  child: Text(
                    'Record voice note',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note_outlined, color: _ink, size: 21),
                    SizedBox(height: 3),
                    Text(
                      'Note & voice',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _ink, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tool(
    String label,
    Widget icon,
    VoidCallback? onPressed, {
    String? tooltip,
  }) {
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _ink,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        textStyle: const TextStyle(fontSize: 11),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(height: 3), Text(label)],
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Widget _buildEventItems() {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final item = _items[index];
          final selected = _selectedCard == index;
          final included = _selectedItemIds.contains(item.id);
          final notePreview = item.type == EventItemType.note
              ? item.text.trim()
              : '';

          final icon = switch (item.type) {
            EventItemType.note => Icons.sticky_note_2_outlined,
            EventItemType.pdf => Icons.picture_as_pdf_outlined,
            EventItemType.photo => Icons.image_outlined,
            EventItemType.audio => Icons.mic_none_rounded,
          };

          return InkWell(
            onTap: _canEdit
                ? () {
                    if (_cameraOpen) _closeCamera();
                    setState(() {
                      if (!_selectedItemIds.add(item.id)) {
                        _selectedItemIds.remove(item.id);
                      }
                    });
                    _selectItem(index);
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 82,
              padding: EdgeInsets.all(item.type == EventItemType.photo ? 2 : 7),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? _green : _line,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.type == EventItemType.photo
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: FutureBuilder<File>(
                            future: _store.file(_scope, item),
                            builder: (context, snapshot) {
                              final file = snapshot.data;
                              if (file == null) {
                                return Icon(icon, color: _muted, size: 25);
                              }
                              return Image.file(
                                file,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    Icon(icon, color: _muted, size: 25),
                              );
                            },
                          ),
                        )
                      : notePreview.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 23),
                          child: Text(
                            notePreview,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                        )
                      : Icon(icon, color: selected ? _green : _muted, size: 25),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      included
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: included ? _green : AppColors.textSecondary,
                      size: 23,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 3),
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
  }

  Widget _buildPreviewCard() {
    final item = _selectedItem!;
    final photo = item.type == EventItemType.photo;
    return LayoutBuilder(
      builder: (context, constraints) => ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildSelectedPreview(),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton.filled(
                tooltip: 'Remove attachment',
                style: _previewIconStyle,
                onPressed: _canEdit && _pendingSaves == 0 && !_saveFailed
                    ? _removeSelectedItem
                    : null,
                icon: const Icon(Icons.close, size: 13),
              ),
            ),
            if (photo || item.type == EventItemType.pdf)
              Positioned(
                bottom: 6,
                left: 6,
                child: IconButton.filled(
                  tooltip: photo ? 'Edit photo' : 'Edit PDF',
                  style: _previewIconStyle,
                  onPressed: _canEdit && _previewFile != null
                      ? (photo ? _editPhoto : _editPdf)
                      : null,
                  icon: const Icon(Icons.edit_outlined, size: 13),
                ),
              ),
            if (photo)
              Positioned(
                bottom: 6,
                right: 6,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth / 2,
                  ),
                  child: TextButton.icon(
                    style: _previewButtonStyle,
                    onPressed: _canEdit ? _editSelectedTag : null,
                    icon: const Icon(Icons.sell_outlined, size: 16),
                    label: Text(
                      item.tag.isEmpty ? 'Tag' : item.tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ButtonStyle get _previewIconStyle => IconButton.styleFrom(
    minimumSize: const Size.square(32),
    fixedSize: const Size.square(32),
    visualDensity: VisualDensity.standard,
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.padded,
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    disabledBackgroundColor: _canvas,
    disabledForegroundColor: _muted,
  );

  ButtonStyle get _previewButtonStyle => TextButton.styleFrom(
    backgroundColor: AppColors.surface,
    foregroundColor: _ink,
    disabledBackgroundColor: _canvas,
    disabledForegroundColor: _muted,
  );

  Future<void> _editSelectedTag() async {
    final item = _selectedItem;
    if (!_canEdit || item == null) return;
    final scope = _scope;
    FocusScope.of(context).unfocus();
    final controller = TextEditingController(text: item.tag);
    String? tag;
    try {
      tag = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.transparent,
          title: Text(
            item.tag.isEmpty ? 'Add tag' : 'Edit tag',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            cursorColor: AppColors.primary,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Tag',
              hintText: 'Enter a tag',
              hintStyle: TextStyle(color: AppColors.hintText),
              labelStyle: TextStyle(color: AppColors.textSecondary),
            ),
            onSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryText,
              ),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      // Wait for the closing dialog animation before disposing its controller.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      controller.dispose();
    }
    if (!mounted || tag == null || !_canEdit || scope != _scope) return;
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index < 0) return;
    setState(() => _items[index] = _items[index].withTag(tag!));
    await _saveDraft();
  }

  Widget _buildSelectedPreview() {
    if (_draftError != null) return _buildSitePrompt();

    final file = _previewFile;
    if (file == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final item = _selectedItem!;
    return EventAttachmentPreview(
      key: ValueKey('${item.id}:$_previewVersion'),
      file: file,
      item: item,
      onEditPdf: _editPdf,
      fillPreview: item.type == EventItemType.pdf,
      fitPhotoWidth: true,
    );
  }

  Widget _buildNoteField() {
    return TextField(
      enabled: _canEdit,
      controller: _noteController,
      focusNode: _noteFocus,
      onChanged: _noteChanged,
      expands: true,
      minLines: null,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textAlignVertical: TextAlignVertical.top,
      cursorColor: _green,
      style: const TextStyle(color: _ink, fontSize: 14, height: 1.5),
      decoration: const InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.all(8),
      ),
    );
  }
}
