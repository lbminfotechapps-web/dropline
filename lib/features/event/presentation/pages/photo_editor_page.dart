import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Annotations use image coordinates so exported marks match the preview.
class PhotoEditorPage extends StatefulWidget {
  const PhotoEditorPage({super.key, required this.file, required this.onSave});

  final File file;
  final Future<void> Function(Uint8List) onSave;

  @override
  State<PhotoEditorPage> createState() => _PhotoEditorPageState();
}

class _Mark {
  _Mark(this.tool, this.color, this.points, {this.text = ''});
  final String tool;
  final Color color;
  final List<Offset> points;
  final String text;
}

class _PhotoEditorPageState extends State<PhotoEditorPage> {
  ui.Image? _image;
  final _marks = <_Mark>[];
  String _tool = 'Draw';
  Color _color = Colors.red;
  bool _saving = false;
  bool _failed = false;
  _Mark? _active;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final codec = await ui.instantiateImageCodec(
        await widget.file.readAsBytes(),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _addText(Offset position) async {
    var enteredText = '';
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add text'),
        content: TextField(
          onChanged: (value) => enteredText = value,
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, enteredText.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (mounted && text != null && text.isNotEmpty) {
      setState(() => _marks.add(_Mark('Text', _color, [position], text: text)));
    }
  }

  Future<void> _save() async {
    final image = _image;
    if (image == null || _saving) return;
    setState(() => _saving = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      _PhotoPainter(
        image,
        _marks,
      ).paint(canvas, Size(image.width.toDouble(), image.height.toDouble()));
      final picture = recorder.endRecording();
      final output = await picture.toImage(image.width, image.height);
      picture.dispose();
      final bytes = await output.toByteData(format: ui.ImageByteFormat.png);
      output.dispose();
      if (bytes == null) throw StateError('Unable to encode photo');
      await widget.onSave(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save photo. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit photo'),
          actions: [
            IconButton(
              tooltip: 'Undo',
              onPressed: !_saving && _marks.isNotEmpty
                  ? () => setState(() => _marks.removeLast())
                  : null,
              icon: const Icon(Icons.undo),
            ),
            TextButton(
              onPressed: image != null && !_saving ? _save : null,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
        body: image == null
            ? Center(
                child: _failed
                    ? const Text('Unable to open photo.')
                    : const CircularProgressIndicator(),
              )
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: image.width / image.height,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            Offset point(Offset local) => Offset(
                              local.dx.clamp(0, constraints.maxWidth) *
                                  image.width /
                                  constraints.maxWidth,
                              local.dy.clamp(0, constraints.maxHeight) *
                                  image.height /
                                  constraints.maxHeight,
                            );
                            return GestureDetector(
                              onTapUp: !_saving && _tool == 'Text'
                                  ? (details) =>
                                        _addText(point(details.localPosition))
                                  : null,
                              onPanStart: !_saving && _tool != 'Text'
                                  ? (details) {
                                      setState(() {
                                        _active = _Mark(_tool, _color, [
                                          point(details.localPosition),
                                        ]);
                                        _marks.add(_active!);
                                      });
                                    }
                                  : null,
                              onPanUpdate: !_saving && _tool != 'Text'
                                  ? (details) {
                                      if (_active != null) {
                                        setState(
                                          () => _active!.points.add(
                                            point(details.localPosition),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              onPanEnd: (_) => _active = null,
                              onPanCancel: () => _active = null,
                              child: CustomPaint(
                                painter: _PhotoPainter(image, _marks),
                                child: const SizedBox.expand(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Draw on the photo, drag a circle, or tap to place text.',
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          children: ['Draw', 'Circle', 'Text']
                              .map(
                                (tool) => ChoiceChip(
                                  label: Text(tool),
                                  selected: _tool == tool,
                                  onSelected: _saving
                                      ? null
                                      : (_) => setState(() => _tool = tool),
                                ),
                              )
                              .toList(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              [
                                    Colors.red,
                                    Colors.yellow,
                                    Colors.green,
                                    Colors.blue,
                                    Colors.white,
                                    Colors.black,
                                  ]
                                  .map(
                                    (color) => IconButton(
                                      tooltip:
                                          '${color == _color ? 'Selected ' : ''}ink color',
                                      onPressed: _saving
                                          ? null
                                          : () =>
                                                setState(() => _color = color),
                                      icon: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: color == _color
                                                ? Colors.grey
                                                : Colors.transparent,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PhotoPainter extends CustomPainter {
  _PhotoPainter(this.image, this.marks);
  final ui.Image image;
  final List<_Mark> marks;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / image.width, size.height / image.height);
    canvas.clipRect(
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    );
    canvas.drawImage(image, Offset.zero, Paint());
    final width = image.width / 180;
    for (final mark in marks) {
      final paint = Paint()
        ..color = mark.color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (mark.tool == 'Text') {
        final text = TextPainter(
          text: TextSpan(
            text: mark.text,
            style: TextStyle(
              color: mark.color,
              fontSize: image.width / 22,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(blurRadius: 2, color: Colors.black54)],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        text.layout(
          maxWidth: (image.width - mark.points.first.dx).clamp(
            1,
            image.width.toDouble(),
          ),
        );
        text.paint(canvas, mark.points.first);
      } else if (mark.tool == 'Circle') {
        canvas.drawOval(
          Rect.fromPoints(mark.points.first, mark.points.last),
          paint,
        );
      } else if (mark.points.length == 1) {
        canvas.drawCircle(
          mark.points.first,
          width / 2,
          Paint()..color = mark.color,
        );
      } else {
        final path = Path()..moveTo(mark.points.first.dx, mark.points.first.dy);
        for (final point in mark.points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PhotoPainter oldDelegate) => true;
}
