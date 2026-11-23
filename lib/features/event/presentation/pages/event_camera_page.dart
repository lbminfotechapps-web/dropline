import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/appcolors.dart';
import 'package:path_provider/path_provider.dart';

import 'photo_editor_page.dart';

class EventCameraActions {
  Future<void> Function()? capture;
}

class EventCameraPage extends StatefulWidget {
  const EventCameraPage({
    super.key,
    required this.onConfirm,
    this.onClose,
    this.inline = false,
    this.actions,
  });

  final Future<void> Function(List<XFile>) onConfirm;
  final VoidCallback? onClose;
  final bool inline;
  final EventCameraActions? actions;

  @override
  State<EventCameraPage> createState() => _EventCameraPageState();
}

class _EventCameraPageState extends State<EventCameraPage>
    with WidgetsBindingObserver {
  CameraController? _camera;
  Directory? _folder;
  final _photos = <File>[];
  final _scroll = ScrollController();
  Future<void> _cameraWork = Future.value();
  bool _active = true;
  bool _busy = false;
  bool _editing = false;
  bool _saving = false;
  String? _error;
  int _selected = -1;
  Size? _viewfinderSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.actions?.capture = _capture;
    _updateCamera();
  }

  void _updateCamera() {
    _cameraWork = _cameraWork.then((_) async {
      final previous = _camera;
      _camera = null;
      if (mounted) setState(() {});
      await previous?.dispose();
      if (!mounted || !_active || _editing) return;
      CameraController? next;
      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) throw StateError('No camera available');
        if (!mounted || !_active || _editing) return;
        final back = cameras.where(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
        next = CameraController(
          back.isEmpty ? cameras.first : back.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await next.initialize();
        if (!mounted || !_active || _editing) {
          await next.dispose();
          return;
        }
        setState(() {
          _camera = next;
          _error = null;
        });
      } catch (_) {
        await next?.dispose();
        if (mounted) {
          setState(
            () => _error =
                'Unable to open camera. Check camera permission and retry.',
          );
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _updateCamera();
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (_busy || _saving || camera == null || !camera.value.isInitialized) {
      return;
    }
    setState(() => _busy = true);
    try {
      final shot = await camera.takePicture();
      _folder ??= await (await getTemporaryDirectory()).createTemp(
        'event_camera_',
      );
      final photo = await _cropToViewfinder(File(shot.path));
      if (!mounted) return;
      if (widget.inline) {
        await widget.onConfirm([XFile(photo.path)]);
        return;
      }
      setState(() {
        _photos.add(photo);
        _selected = _photos.length - 1;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      _message('Unable to capture photo. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<File> _cropToViewfinder(File source) async {
    final size = _viewfinderSize;
    if (size == null || size.isEmpty) {
      throw StateError('Camera preview is not ready');
    }
    final codec = await ui.instantiateImageCodec(await source.readAsBytes());
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final imageSize = Size(image.width.toDouble(), image.height.toDouble());
        final fitted = applyBoxFit(BoxFit.cover, imageSize, size);
        final crop = Alignment.center.inscribe(fitted.source, Offset.zero & imageSize);
        final width = crop.width.round();
        final height = crop.height.round();
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawImageRect(
          image,
          crop,
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          Paint(),
        );
        final picture = recorder.endRecording();
        try {
          final cropped = await picture.toImage(width, height);
          try {
            final bytes = await cropped.toByteData(format: ui.ImageByteFormat.png);
            if (bytes == null) throw StateError('Unable to encode photo');
            final photo = File(
              '${_folder!.path}/${DateTime.now().microsecondsSinceEpoch}.png',
            );
            await photo.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
            return photo;
          } finally {
            cropped.dispose();
          }
        } finally {
          picture.dispose();
        }
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  Future<void> _edit() async {
    if (_selected < 0 || _busy || _saving) return;
    final file = _photos[_selected];
    _editing = true;
    _updateCamera();
    await _cameraWork;
    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PhotoEditorPage(
          file: file,
          onSave: (bytes) async {
            final temporary = File('${file.path}.tmp');
            await temporary.writeAsBytes(bytes, flush: true);
            await temporary.rename(file.path);
            await FileImage(file).evict();
          },
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _editing = false);
    _updateCamera();
  }

  Future<void> _confirm() async {
    if (_photos.isEmpty || _busy || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onConfirm(_photos.map((file) => XFile(file.path)).toList());
      if (mounted) {
        if (widget.onClose != null) {
          widget.onClose!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      _message('Unable to attach photos. Please try again.');
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.actions?.capture = null;
    _active = false;
    unawaited(
      _cameraWork.then((_) async {
        await _camera?.dispose();
        final folder = _folder;
        if (folder != null && await folder.exists()) {
          await folder.delete(recursive: true);
        }
      }),
    );
    _scroll.dispose();
    super.dispose();
  }

  static const _panelColor = Color(0xFF101E2B);

  @override
  Widget build(BuildContext context) {
    final locked = _busy || _saving || _editing;
    if (widget.inline) return _buildInlineCamera(locked);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _panelColor,
      ),
      child: PopScope(
        canPop: !locked && widget.onClose == null,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !locked) widget.onClose?.call();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF080F16),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Close camera',
                        onPressed: locked
                            ? null
                            : () {
                                if (widget.onClose != null) {
                                  widget.onClose!();
                                } else {
                                  Navigator.maybePop(context);
                                }
                              },
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Camera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PHOTO',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final landscape =
                          constraints.maxWidth > constraints.maxHeight;
                      if (landscape) {
                        return Row(
                          children: [
                            Expanded(child: _buildViewfinder()),
                            SizedBox(
                              width: 300,
                              child: _buildCapturePanel(locked),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Expanded(child: _buildViewfinder()),
                          _buildCapturePanel(locked),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineCamera(bool locked) {
    return Stack(
            fit: StackFit.expand,
            children: [
              _buildViewfinder(),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filled(
                  tooltip: 'Close camera',
                  onPressed: locked ? null : widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
    );
  }

  Widget _buildViewfinder() {
    final camera = _camera;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_error != null)
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.no_photography_outlined,
                          color: AppColors.textSecondary,
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _updateCamera,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (camera == null)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    _viewfinderSize = constraints.biggest;
                    final aspectRatio = camera.value.aspectRatio;
                    final portrait = MediaQuery.orientationOf(context) ==
                        Orientation.portrait;
                    return ClipRect(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: portrait ? 1 : aspectRatio,
                          height: portrait ? aspectRatio : 1,
                          child: CameraPreview(camera),
                        ),
                      ),
                    );
                  },
                ),
              if (!widget.inline && camera != null && _error == null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Keep capturing • Review below',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapturePanel(bool locked) {
    final hasPhotos = _photos.isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasPhotos
                        ? '${_photos.length} photos captured'
                        : 'Your photos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasPhotos)
                  Text(
                    '${_selected + 1} selected',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: hasPhotos
                  ? ListView.separated(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) =>
                          _buildThumbnail(index, locked),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.collections_outlined,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Captured photos appear here',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            SizedBox(
              height: 44,
              child: hasPhotos
                  ? Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          onPressed: locked ? null : _edit,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text(
                            'Edit photo',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          onPressed: locked
                              ? null
                              : () => setState(() {
                                  _photos.removeAt(_selected);
                                  _selected = _photos.isEmpty
                                      ? -1
                                      : _photos.length - 1;
                                }),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Remove',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Text(
                        'Take multiple photos, then tap OK',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
            ),
            const Divider(color: Color(0xFF263440), height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_photos.length} photos',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Capture photo',
                  child: Tooltip(
                    message: 'Capture photo',
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: OutlinedButton(
                        onPressed: !locked && _camera != null ? _capture : null,
                        style: OutlinedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(5),
                          side: BorderSide(
                            color: !locked && _camera != null
                                ? Colors.white
                                : Colors.white30,
                            width: 3,
                          ),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: !locked && _camera != null
                                ? Colors.white
                                : Colors.white24,
                          ),
                          child: Center(
                            child: _busy
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.background,
                                    ),
                                  )
                                : const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 48,
                  child: FilledButton(
                    onPressed: !locked && hasPhotos ? _confirm : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryText,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.08,
                      ),
                      disabledForegroundColor: Colors.white38,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 18),
                              SizedBox(width: 4),
                              Text('OK'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(int index, bool locked) {
    final selected = index == _selected;
    return Semantics(
      label: 'Photo ${index + 1}',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: locked ? null : () => setState(() => _selected = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 70,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.white24,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  _photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: _panelColor,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 18,
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
