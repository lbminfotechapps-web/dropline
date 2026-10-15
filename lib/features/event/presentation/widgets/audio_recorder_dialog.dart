import 'dart:async';
import 'dart:io';

import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderDialog extends StatefulWidget {
  const AudioRecorderDialog({super.key});

  @override
  State<AudioRecorderDialog> createState() => _AudioRecorderDialogState();
}

class _AudioRecorderDialogState extends State<AudioRecorderDialog>
    with WidgetsBindingObserver {
  AudioRecorder? _recorder;
  bool _keepRecording = false;
  final _watch = Stopwatch();
  Timer? _timer;
  bool _recording = false;
  bool _busy = false;
  String? _path;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive && _recording && !_busy) {
      unawaited(_stop());
    }
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission()) {
        if (mounted) {
          setState(
            () => _error =
                'Microphone access is needed. Please enable it in your device settings.',
          );
        }
        return;
      }
      if (!mounted) return;
      final directory = await getApplicationDocumentsDirectory();
      if (!mounted) return;
      final path =
          '${directory.path}/voice_note_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await recorder.start(const RecordConfig(), path: path);
      if (!mounted) return;
      _watch.reset();
      _watch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
      if (mounted) setState(() => _recording = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is MissingPluginException
              ? 'The recorder is not loaded. Stop the app completely and rebuild it, then try again.'
              : 'Unable to start recording. Check microphone access in your device settings and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    try {
      final path = await _recorder!.stop();
      _watch.stop();
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _recording = false;
          _path = path;
          if (path == null) {
            _error = 'No recording was saved. Please try again.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to stop recording. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _cancel() {
    // Closing must not depend on a native plugin responding successfully.
    Navigator.of(context).pop();
  }

  Future<void> _releaseRecorder() async {
    final recorder = _recorder;
    if (recorder == null) return;
    try {
      if (!_keepRecording) {
        await recorder.cancel().timeout(const Duration(seconds: 5));
      }
    } catch (error) {
      debugPrint('Recorder cleanup: $error');
    } finally {
      try {
        await recorder.dispose().timeout(const Duration(seconds: 5));
      } catch (error) {
        debugPrint('Recorder disposal: $error');
      }
      if (!_keepRecording && _path != null) {
        try {
          final file = File(_path!);
          if (await file.exists()) await file.delete();
        } catch (error) {
          debugPrint('Recording file cleanup: $error');
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _watch.stop();
    unawaited(_releaseRecorder());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _watch.elapsed.inSeconds;
    final colour = Theme.of(context).colorScheme.onSurface;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Voice note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _recording ? Icons.mic : Icons.mic_none_rounded,
              size: 48,
              color: _recording
                  ? AppColors.error
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
              style: AppTextStyles.headingLarge.copyWith(color: colour),
            ),
            const SizedBox(height: 8),
            Text(
              _recording
                  ? 'Recording…'
                  : _path != null
                  ? 'Ready to attach'
                  : 'Tap Start to record',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: _cancel, child: const Text('Cancel')),
          FilledButton(
            onPressed: _busy
                ? null
                : _recording
                ? _stop
                : _path != null
                ? () {
                    _keepRecording = true;
                    Navigator.of(context).pop(_path);
                  }
                : _start,
            child: Text(
              _busy
                  ? 'Please wait…'
                  : _recording
                  ? 'Stop'
                  : _path != null
                  ? 'Attach'
                  : 'Start',
            ),
          ),
        ],
      ),
    );
  }
}
