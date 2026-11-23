import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../data/repositories/event_draft_store.dart';

class EventAttachmentPreview extends StatelessWidget {
  const EventAttachmentPreview({
    super.key,
    required this.file,
    required this.item,
    required this.onEditPdf,
    this.fillPreview = false,
    this.fitPhotoWidth = false,
    this.alignTop = false,
  });

  final File file;
  final EventDraftItem item;
  final VoidCallback onEditPdf;
  final bool fillPreview;
  final bool fitPhotoWidth;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    if (!file.existsSync()) {
      return const Center(child: Text('This file is no longer available.'));
    }
    switch (item.type) {
      case EventItemType.photo:
        if (fitPhotoWidth) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return ClipRect(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Image.file(
                      file,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, _, _) {
                        return const Center(
                          child: Text(
                            'Unable to open photo.',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        }
        return InteractiveViewer(
          child: SizedBox.expand(
            child: Image.file(
              file,
              width: double.infinity,
              height: double.infinity,
              fit: fillPreview ? BoxFit.cover : BoxFit.contain,
              alignment: alignTop ? Alignment.topCenter : Alignment.center,
              errorBuilder: (_, _, _) =>
                  const Center(child: Text('Unable to open photo.')),
            ),
          ),
        );
      case EventItemType.pdf:
        if (fillPreview) {
          return SfPdfViewer.file(
            file,
            pageLayoutMode: PdfPageLayoutMode.continuous,
            scrollDirection: PdfScrollDirection.vertical,
          );
        }
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEditPdf,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.edit),
                label: const Text('Edit PDF'),
              ),
            ),
            Expanded(
              child: SfPdfViewer.file(
                file,
                pageLayoutMode: PdfPageLayoutMode.continuous,
                scrollDirection: PdfScrollDirection.vertical,
              ),
            ),
          ],
        );
      case EventItemType.audio:
        return _AudioPreview(path: file.path, name: 'Voice note', alignTop: alignTop);
      case EventItemType.note:
        return const SizedBox.shrink();
    }
  }
}

class _AudioPreview extends StatefulWidget {
  const _AudioPreview({required this.path, required this.name, this.alignTop = false});
  final String path;
  final String name;
  final bool alignTop;

  @override
  State<_AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<_AudioPreview> {
  final _player = AudioPlayer();
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.setFilePath(widget.path);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to play this recording.');
    }
  }

  Future<void> _toggle() async {
    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to play this recording.');
    }
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: widget.alignTop ? Alignment.topCenter : Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.audiotrack, size: 48),
        const SizedBox(height: 12),
        if (_error != null) Text(_error!),
        if (_error == null && !_ready) const CircularProgressIndicator(),
        if (_ready) ...[
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (_, snapshot) => IconButton(
              tooltip: _player.playing ? 'Pause' : 'Play',
              iconSize: 48,
              onPressed: _toggle,
              icon: Icon(
                _player.playing ? Icons.pause_circle : Icons.play_circle,
              ),
            ),
          ),
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (_, snapshot) {
              final duration = _player.duration?.inMilliseconds ?? 0;
              final position = (snapshot.data?.inMilliseconds ?? 0).clamp(
                0,
                duration,
              );
              return Slider(
                value: position.toDouble(),
                max: duration > 0 ? duration.toDouble() : 1,
                onChanged: duration > 0
                    ? (value) =>
                          _player.seek(Duration(milliseconds: value.round()))
                    : null,
              );
            },
          ),
        ],
      ],
    ),
  );
}
