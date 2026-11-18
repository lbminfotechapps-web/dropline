import 'dart:async';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'dart:io';
import 'package:dropline/features/event/domain/entities/event_draft_scope.dart';
import 'package:dropline/features/event/domain/entities/location_flow_args.dart';
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

import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:dropline/core/theme/appcolors.dart';

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
  });
  final String projectId;
  final String projectName;

  final VoidCallback? onCamera;
  final VoidCallback? onRecordAudio;

  final TimeSlotRemoteDataSource? timeSlotDataSource;
  final EventDraftStore? draftStore;

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  final _timeController = ScrollController();
  late final EventDraftStore _store;
  final _draftDate = DateTime.now();
  List<EventDraftItem> _items = [];
  bool _attachmentValidationAttempted = false;
  final Set<String> _selectedAttachmentIds = {};

  bool get _hasAttachment => _items.any(
    (item) =>
        _selectedAttachmentIds.contains(item.id) &&
        (item.type == EventItemType.photo ||
            item.type == EventItemType.pdf ||
            item.type == EventItemType.audio),
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
      selectedItemIds: Set<String>.unmodifiable(_selectedAttachmentIds),
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_timeController.hasClients) return;
        final offset =
            2 +
            selected * 88 +
            40.5 -
            _timeController.position.viewportDimension / 2;
        _timeController.jumpTo(
          offset.clamp(0.0, _timeController.position.maxScrollExtent),
        );
      });
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
        _selectedAttachmentIds.removeWhere(
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

  Future<void> _selectTime(int index) async {
    if (!_canEdit || _saveFailed || _pendingSaves > 0) return;
    FocusScope.of(context).unfocus();
    setState(() => _selectedTime = index);
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
    if (_selectedItem == null) {
      setState(() {
        _items.add(
          EventDraftItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            type: EventItemType.note,
            name: 'Note 1',
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

  Future<void> _pickAttachment(FileType type) async {
    if (!_canEdit) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: type == FileType.custom ? ['pdf'] : null,
      );
      if (!mounted) return;
      await _addFiles(
        result.map((file) => file.xFile).toList(),
        type == FileType.audio ? EventItemType.audio : EventItemType.pdf,
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
    setState(() => _picking = true);
    try {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EventCameraPage(onConfirm: _attachCameraPhotos),
        ),
      );
    } catch (_) {
      _message('Unable to open camera. Check camera access and try again.');
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
    setState(() => _attachmentValidationAttempted = true);
    if (_attachmentInvalid) return;

    if (!_canEdit ||
        _saveFailed ||
        _pendingSaves > 0 ||
        _picking ||
        _userId.isEmpty ||
        _userId == 'local' ||
        widget.projectId.trim().isEmpty) {
      return;
    }

    final scope = _eventDraftScope;

    final saved = await _saveDraft();

    if (!mounted || !saved) return;

    await context.push(
      AppRouter.mainAreas,
      extra: LocationFlowArgs(scope: scope, projectName: widget.projectName),
    );
    if (mounted) await _loadDraft();
  }

  String get _eventDateLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${days[_draftDate.weekday - 1]} '
        '${_draftDate.day} '
        '${months[_draftDate.month - 1]}';
  }

  Widget _buildDateHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          color: AppColors.iconColor,
          size: 15,
        ),
        const SizedBox(width: 7),
        Text(
          _eventDateLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_saveFailed)
          TextButton(
            onPressed: _saveDraft,
            child: const Text(
              'Retry save',
              style: TextStyle(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    if (_loadingTimeSlots) {
      return const SizedBox(
        height: 43,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_timeSlotsFailed || _timeSlots.isEmpty) {
      return SizedBox(
        height: 43,
        child: TextButton(
          onPressed: _loadTimeSlots,
          child: const Text('Retry loading time slots'),
        ),
      );
    }

    return SizedBox(
      height: 43,
      child: ListView.builder(
        controller: _timeController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: _timeSlots.length,
        itemExtent: 88,
        itemBuilder: (context, index) {
          final selected = _selectedTime == index;
          final hasData = _slotsWithData.contains(_timeSlots[index].id);

          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: InkWell(
              onTap: _canEdit ? () => _selectTime(index) : null,
              borderRadius: BorderRadius.circular(11),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minWidth: 61),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected || hasData
                      ? AppColors.primary
                      : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: hasData
                        ? AppColors.success
                        : selected
                        ? AppColors.primary
                        : AppColors.border,
                    width: selected || hasData ? 2 : 1,
                  ),
                ),
                child: Text(
                  _timeLabel(index),
                  style: TextStyle(
                    color: selected || hasData
                        ? AppColors.primaryText
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: PopScope(
        canPop: _pendingSaves == 0 && !_picking && !_saveFailed,
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
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          appBar: CustomAppBar(
            title: _punchProjectName ?? widget.projectName,
            onBackPressed: () => context.push(AppRouter.punchOut),
            subtitleWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.work_outline_rounded,
                    color: AppColors.iconColor,
                    size: 13,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Project',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          //  _buildEventHeader(),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, _) {
                final editingNote =
                    _selectedItem?.type == EventItemType.note &&
                    keyboardVisible;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildPreviewCard(),
                            ),
                            if (!editingNote)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildItemsHeader(),
                                  _buildDateHeader(),
                                ],
                              ),

                              const SizedBox(height: 6),

                              if (_items.isNotEmpty) _buildEventItems(),

                              const SizedBox(height: 8),

                              if (_attachmentInvalid) ...[
                                const Text(
                                  'Select at least one image, PDF or audio attachment.',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              _buildTimeSlots(),

                              const SizedBox(height: 8),

                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  // border: _attachmentInvalid
                                  //     ? Border.all(
                                  //         color: Colors.redAccent,
                                  //         width: 1.5,
                                  //       )
                                  //     : null,
                                ),
                                child: _buildBottomTools(),
                              ),
                              const SizedBox(height: 8),

                              _buildBottomActions(),

                              const SizedBox(height: 6),

                              Center(
                                child: Text(
                                  _saveFailed
                                      ? 'Save failed. Retry before leaving.'
                                      : _pendingSaves > 0
                                      ? 'Saving changes...'
                                      : _loadingDraft || _loadingTimeSlots
                                      ? 'Loading...'
                                      : _items.isEmpty
                                      ? 'Add an item, then tap Save update.'
                                      : 'Changes are saved locally.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _saveFailed
                                        ? AppColors.error
                                        : AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                                      ],
                                    ),
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final busy = !_canEdit || _pendingSaves > 0 || _saveFailed || _picking;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 49,
            child: OutlinedButton.icon(
              onPressed: busy ? null : _completeEvent,
              icon: const Icon(
                Icons.layers_outlined,
                size: 17,
                color: AppColors.textPrimary,
              ),
              label: const Text(
                'Add Event',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Expanded(
        //   child: SizedBox(
        //     height: 49,
        //     child: ElevatedButton.icon(
        //       onPressed: busyss
        //           ? null
        //           : () async {
        //               final saved = await _saveDraft();
        //               if (!mounted) return;

        //               if (saved) {
        //                 _message('Event draft saved locally.');
        //               } else {
        //                 _message('Unable to save event draft.');
        //               }
        //             },
        //       icon: const Icon(Icons.check_rounded, size: 18),
        //       label: const Text('Save update'),
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: AppColors.primary,
        //         foregroundColor: AppColors.primaryText,
        //         disabledBackgroundColor: AppColors.disabledButton,
        //         disabledForegroundColor: AppColors.disabledText,
        //         elevation: 0,
        //         padding: const EdgeInsets.symmetric(horizontal: 7),
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(12),
        //         ),
        //         textStyle: const TextStyle(
        //           fontSize: 12,
        //           fontWeight: FontWeight.w500,
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildBottomTools() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _eventTool(
              label: 'PDF',
              icon: Icons.description_outlined,
              onTap: () => _pickAttachment(FileType.custom),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 56),
                child: AspectRatio(
                aspectRatio: 1,
                child: Semantics(
                  label: 'Take a photo',
                  button: true,
                  child: InkWell(
                    onTap: _canEdit ? widget.onCamera ?? _takePhoto : null,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Photo',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _eventTool(
              label: 'Note',
              icon: Icons.edit_note_rounded,
              onTap: _newNote,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _eventTool(
              label: 'Audio',
              icon: Icons.mic_none_rounded,
              onTap: widget.onRecordAudio ?? _openRecorder,
            ),
          ),
        ),
      ],
    );
  }

  Widget _eventTool({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF30485C),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _canEdit ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA9CFA0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: _canEdit ? AppColors.iconColor : AppColors.disabledText,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsHeader() => Text(
    '${_items.length} items · ${_selectedAttachmentIds.length} selected',
    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
  );

  Widget _buildEventItems() {
    if (_items.isEmpty) {
      return Container(
        height: 65,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No items added yet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      );
    }

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final item = _items[index];
          final selected = _selectedCard == index;

          final icon = switch (item.type) {
            EventItemType.note => Icons.sticky_note_2_outlined,
            EventItemType.pdf => Icons.picture_as_pdf_outlined,
            EventItemType.photo => Icons.image_outlined,
            EventItemType.audio => Icons.mic_none_rounded,
          };

          return InkWell(
            onTap: _canEdit
                ? () {
                    if (item.type != EventItemType.note) {
                      setState(() {
                        if (!_selectedAttachmentIds.add(item.id)) {
                          _selectedAttachmentIds.remove(item.id);
                        }
                      });
                    }
                    _selectItem(index);
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 88,
              padding: EdgeInsets.all(item.type == EventItemType.photo ? 2 : 7),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
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
                                return Icon(
                                  icon,
                                  color: AppColors.iconColor,
                                  size: 25,
                                );
                              }
                              return Image.file(
                                file,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Icon(
                                  icon,
                                  color: AppColors.iconColor,
                                  size: 25,
                                ),
                              );
                            },
                          ),
                        )
                      : Icon(
                          icon,
                          color: selected
                              ? AppColors.primary
                              : AppColors.iconColor,
                          size: 25,
                        ),
                  if (item.type != EventItemType.note)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Icon(
                        _selectedAttachmentIds.contains(item.id)
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _selectedAttachmentIds.contains(item.id)
                            ? AppColors.primary
                            : Colors.white,
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
    final item = _selectedItem;

    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF192A3B),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF152435),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildSelectedPreview(),
              ),
            ),
          ],
        ),
      );
    }

    if (item.type == EventItemType.photo || item.type == EventItemType.pdf) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: AppColors.inputBackground,
                child: _buildSelectedPreview(),
              ),
              Positioned(
                bottom: 10,
                left: 12,
                right: 62,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xA6000000),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_timeLabel(_selectedTime)} · ${_selectedCard + 1} / ${_items.length}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (item.type == EventItemType.photo) ...[
                Positioned(
                  bottom: 54,
                  left: 12,
                  right: 12,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: _canEdit ? _editSelectedTag : null,
                      icon: const Icon(Icons.sell_outlined, size: 14),
                      label: Text(
                        item.tag.isEmpty ? 'Add tag' : item.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xB3000000),
                        foregroundColor: AppColors.primary,
                        disabledForegroundColor: AppColors.disabledText,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 36),
                        textStyle: const TextStyle(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 8,
                  child: IconButton.filled(
                    tooltip: 'Edit photo',
                    onPressed: _canEdit && _previewFile != null
                        ? _editPhoto
                        : null,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xB3000000),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xB3000000),
                      minimumSize: const Size(40, 40),
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
              if (item.type == EventItemType.pdf)
                Positioned(
                  right: 10,
                  bottom: 8,
                  child: FilledButton.icon(
                    onPressed: _canEdit ? _editPdf : null,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (item.type == EventItemType.note)
                TextButton.icon(
                  onPressed: () => _noteFocus.unfocus(),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Done'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              const Spacer(),
              Text(
                _selectedCard >= 0
                    ? '${_selectedCard + 1} / ${_items.length}'
                    : '0 / ${_items.length}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(13),
              ),
              child: _buildSelectedPreview(),
            ),
          ),

          if (item.type != EventItemType.note ||
              MediaQuery.viewInsetsOf(context).bottom == 0) ...[
            const SizedBox(height: 9),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _timeLabel(_selectedTime),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                if (item.type == EventItemType.pdf)
                  TextButton.icon(
                    onPressed: _canEdit ? _editPdf : null,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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
    if (_selectedItem?.type == EventItemType.photo) {
      return _buildSelectedPreviewContent();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: OutlinedButton.icon(
            onPressed: _canEdit && _selectedItem != null
                ? _editSelectedTag
                : null,
            icon: const Icon(Icons.sell_outlined, size: 16),
            label: Text(
              _selectedItem?.tag.isNotEmpty == true
                  ? _selectedItem!.tag
                  : 'Tag',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.disabledText,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 36),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildSelectedPreviewContent()),
      ],
    );
  }

  Widget _buildSelectedPreviewContent() {
    if (_loadingDraft) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_draftError != null) {
      return Center(
        child: TextButton(
          onPressed: _timeSlots.isEmpty ? null : _loadDraft,
          child: Text(_draftError!, textAlign: TextAlign.center),
        ),
      );
    }

    final item = _selectedItem;

    if (item == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_copy_outlined,
              color: AppColors.iconColor,
              size: 34,
            ),
            SizedBox(height: 9),
            Text(
              'No items for this time',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Tap Note, Audio, Photo or PDF below to add\nyour first item.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (item.type != EventItemType.note) {
      if (_previewFile == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: EventAttachmentPreview(
          key: ValueKey('${item.id}:$_previewVersion'),
          file: _previewFile!,
          item: item,
          onEditPdf: _editPdf,
          fillPreview: true,
        ),
      );
    }

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
      cursorColor: AppColors.primary,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        height: 1.5,
      ),
      decoration: const InputDecoration(
        hintText: 'Write your site note...',
        hintStyle: TextStyle(color: AppColors.hintText, fontSize: 13),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.all(8),
      ),
    );
  }

  Widget _tool(
    String label,
    IconData icon,
    Color colour,
    VoidCallback onTap,
    double scale,
  ) {
    return SizedBox(
      width: 47 * scale,
      height: 48 * scale,
      child: IconButton.filled(
        tooltip: label,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: colour,
          foregroundColor: AppColors.primaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scale),
          ),
        ),
        icon: Icon(icon, size: 24 * scale),
      ),
    );
  }
}
