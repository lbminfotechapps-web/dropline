import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:dropline/features/event/domain/entities/event_draft_scope.dart';
import 'package:dropline/features/event/domain/entities/location_flow_args.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'package:dropline/features/pdf_editor_page.dart';
import '../../data/repositories/event_draft_store.dart';
import '../widgets/event_attachment_preview.dart';
import 'package:dropline/core/api_constant/dio_client.dart';
import 'package:dropline/features/event/data/datasources/time_slot_remote_datasource.dart';

import 'package:dropline/core/router/app_router.dart';
import 'package:go_router/go_router.dart';

import '../widgets/audio_recorder_dialog.dart';

import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
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
  String _userId = 'local';
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
    );
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
        final parts = slots[index].time.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;
        final minutes = hour * 60 + minute;
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
      } else {
        setState(() => _loadingDraft = false);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_timeController.hasClients) return;
        final scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.8, 1.4);
        final offset =
            12 +
            selected * 83 * scale +
            38 * scale -
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
        _items = items;
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
    final items = List<EventDraftItem>.of(_items);
    final version = ++_saveVersion;
    setState(() => _pendingSaves++);
    try {
      await _store.save(scope, items);
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
    _noteFocus.requestFocus();
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

  Future<void> _takePhoto() async {
    if (!_canEdit) return;
    FocusScope.of(context).unfocus();
    setState(() => _picking = true);
    try {
      await _store.rememberCameraScope(_scope);
      final photo = await ImagePicker().pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        await _addFiles([photo], EventItemType.photo);
      }
      await _store.rememberCameraScope(null);
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
      extra: LocationFlowArgs(scope: scope, projectName: widget.projectName,),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
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
          backgroundColor: AppColors.eventBackgroundBottom,
          body: AppBackground(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = (constraints.maxWidth / 390).clamp(0.8, 1.4);
                  final horizontal = 26 * scale;
                  final cardHeight = math.max(
                    245.0,
                    constraints.maxHeight - 305 * scale,
                  );
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      top: 18 * scale,
                      bottom: 12 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontal),
                          child: Row(
                            children: [
                              Container(
                                width: 30 * scale,
                                height: 30 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  border: Border.all(
                                    color: AppColors.white.withValues(
                                      alpha: 0.16,
                                    ),
                                  ),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Back',
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                  icon: Icon(
                                    Icons.arrow_back_rounded,
                                    size: 24 * scale,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10 * scale),
                              Text(
                                widget.projectName,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontSize: 20 * scale,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10 * scale),
                        Container(
                          height: cardHeight,
                          margin: EdgeInsets.symmetric(horizontal: horizontal),
                          padding: EdgeInsets.fromLTRB(
                            12 * scale,
                            10 * scale,
                            12 * scale,
                            4 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.eventNoteSurface,
                            borderRadius: BorderRadius.circular(26 * scale),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: _loadingDraft
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : _draftError != null
                                    ? Center(
                                        child: TextButton(
                                          onPressed: _timeSlots.isEmpty
                                              ? null
                                              : _loadDraft,
                                          child: Text(_draftError!),
                                        ),
                                      )
                                    : _selectedItem != null &&
                                          _selectedItem!.type !=
                                              EventItemType.note
                                    ? _previewFile == null
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : EventAttachmentPreview(
                                              key: ValueKey(
                                                '${_selectedItem!.id}:$_previewVersion',
                                              ),
                                              file: _previewFile!,
                                              item: _selectedItem!,
                                              onEditPdf: _editPdf,
                                            )
                                    : TextField(
                                        enabled: _canEdit,
                                        onChanged: _noteChanged,
                                        controller: _noteController,
                                        focusNode: _noteFocus,
                                        expands: true,
                                        minLines: null,
                                        maxLines: null,
                                        textAlignVertical:
                                            TextAlignVertical.top,
                                        keyboardType: TextInputType.multiline,
                                        cursorColor: AppColors.white,
                                        style: AppTextStyles.inputText.copyWith(
                                          fontSize: 16 * scale,
                                          height: 1.5,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Write a note...',
                                          hintStyle: AppTextStyles.inputHint
                                              .copyWith(
                                                fontSize: 16 * scale,
                                                color: AppColors.textSecondary,
                                              ),
                                          filled: false,
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.all(
                                            6 * scale,
                                          ),
                                        ),
                                      ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _timeLabel(_selectedTime),
                                    style: AppTextStyles.headingLarge.copyWith(
                                      fontSize: 30 * scale,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Record voice note',
                                    onPressed:
                                        widget.onRecordAudio ?? _openRecorder,
                                    icon: const Icon(
                                      Icons.mic_none_rounded,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit note',
                                    onPressed: !_canEdit
                                        ? null
                                        : () {
                                            if (_selectedItem?.type ==
                                                EventItemType.note) {
                                              _noteFocus.requestFocus();
                                            } else {
                                              _newNote();
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.edit_square,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 13 * scale),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontal),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_draftDate.day}/${_draftDate.month}/${_draftDate.year} • '
                                  '${_items.length} items',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                              if (_saveFailed)
                                TextButton(
                                  onPressed: _saveDraft,
                                  child: const Text('Save failed. Retry'),
                                )
                              else
                                Text(
                                  _loadingTimeSlots || _loadingDraft
                                      ? 'Loading…'
                                      : _timeSlotsFailed || _draftError != null
                                      ? 'Not loaded'
                                      : _pendingSaves > 0 || _picking
                                      ? 'Saving…'
                                      : 'Saved locally',
                                  style: AppTextStyles.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 64 * scale,
                          child: _items.isEmpty
                              ? Center(
                                  child: Text(
                                    'Add a note, PDF, photo or audio for this time slot.',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontal,
                                  ),
                                  itemCount: _items.length,
                                  separatorBuilder: (_, _) =>
                                      SizedBox(width: 10 * scale),
                                  itemBuilder: (_, index) {
                                    final item = _items[index];
                                    return Semantics(
                                      selected: _selectedCard == index,
                                      child: Tooltip(
                                        message: item.name,
                                        child: InkWell(
                                          onTap: _canEdit
                                              ? () => _selectItem(index)
                                              : null,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            width: 76 * scale,
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: AppColors.eventTileLight,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _selectedCard == index
                                                    ? AppColors
                                                          .eventTimeSelected
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  switch (item.type) {
                                                    EventItemType.note =>
                                                      Icons.edit_note,
                                                    EventItemType.pdf =>
                                                      Icons.picture_as_pdf,
                                                    EventItemType.photo =>
                                                      Icons.photo_camera,
                                                    EventItemType.audio =>
                                                      Icons.audiotrack,
                                                  },
                                                  color: AppColors.black,
                                                  size: 22 * scale,
                                                ),
                                                Text(
                                                  item.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: AppColors.black,
                                                    fontSize: 10 * scale,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        SizedBox(height: 17 * scale),
                        SizedBox(
                          height: 34 * scale,
                          child: _loadingTimeSlots
                              ? const Center(child: CircularProgressIndicator())
                              : _timeSlotsFailed || _timeSlots.isEmpty
                              ? Center(
                                  child: TextButton(
                                    onPressed: _loadTimeSlots,
                                    child: Text(
                                      _timeSlotsFailed
                                          ? 'Unable to load time slots. Retry'
                                          : 'No time slots available. Retry',
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: _timeController,
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  itemCount: _timeSlots.length,
                                  separatorBuilder: (_, index) =>
                                      SizedBox(width: 7 * scale),
                                  itemBuilder: (context, index) => Semantics(
                                    selected: _selectedTime == index,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () => _selectTime(index),
                                      child: Container(
                                        width: 76 * scale,
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 9 * scale,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.white.withValues(
                                            alpha: 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: _selectedTime == index
                                                ? AppColors.eventTimeSelected
                                                : AppColors.white.withValues(
                                                    alpha: 0.18,
                                                  ),
                                            width: _selectedTime == index
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                        child: Text(
                                          _timeLabel(index),
                                          style: AppTextStyles.titleSmall
                                              .copyWith(fontSize: 15 * scale),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        SizedBox(height: 14 * scale),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 19 * scale),
                          padding: EdgeInsets.all(13 * scale),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(28 * scale),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _tool(
                                'Attach PDF',
                                Icons.picture_as_pdf_outlined,
                                AppColors.eventToolBlue,
                                () => _pickAttachment(FileType.custom),
                                scale,
                              ),
                              _tool(
                                'Write note',
                                Icons.edit_note_rounded,
                                AppColors.eventToolMint,
                                _newNote,
                                scale,
                              ),
                              _tool(
                                'Add photo',
                                Icons.camera_alt_outlined,
                                AppColors.eventToolPurple,
                                widget.onCamera ?? _takePhoto,
                                scale,
                              ),
                              _tool(
                                'Record voice note',
                                Icons.mic_none_rounded,
                                AppColors.eventToolOrange,
                                widget.onRecordAudio ?? _openRecorder,
                                scale,
                              ),
                              SizedBox(
                                height: 48 * scale,
                                child: FilledButton(
                                  onPressed: _canEdit ? _completeEvent : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.eventToolCyan,
                                    foregroundColor: AppColors.black,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 18 * scale,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        17 * scale,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Event',
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: AppColors.black,
                                      fontSize: 15 * scale,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
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
          foregroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scale),
          ),
        ),
        icon: Icon(icon, size: 24 * scale),
      ),
    );
  }
}
