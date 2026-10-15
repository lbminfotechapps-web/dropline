import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

enum PdfDrawingTool { pencil, rectangle, circle, line }

class PdfDrawing {
  PdfDrawing(this.tool, this.color, this.width, this.points);
  final PdfDrawingTool tool;
  final Color color;
  final double width;
  final List<Offset> points;
}

/// Points use page coordinates, independent of the preview's screen size.
void paintPdfDrawings(pdf.PdfPage page, List<PdfDrawing> drawings) {
  for (final drawing in drawings) {
    if (drawing.points.isEmpty) continue;
    final pen = pdf.PdfPen(
      pdf.PdfColor(
        drawing.color.r * 255 ~/ 1,
        drawing.color.g * 255 ~/ 1,
        drawing.color.b * 255 ~/ 1,
      ),
      width: drawing.width,
    );
    final bounds = Rect.fromPoints(drawing.points.first, drawing.points.last);
    switch (drawing.tool) {
      case PdfDrawingTool.pencil:
        if (drawing.points.length == 1) {
          page.graphics.drawEllipse(
            Rect.fromCircle(
              center: drawing.points.first,
              radius: drawing.width / 2,
            ),
            brush: pdf.PdfSolidBrush(pen.color),
          );
        } else {
          for (int i = 1; i < drawing.points.length; i++) {
            page.graphics.drawLine(
              pen,
              drawing.points[i - 1],
              drawing.points[i],
            );
          }
        }
      case PdfDrawingTool.line:
        page.graphics.drawLine(pen, drawing.points.first, drawing.points.last);
      case PdfDrawingTool.rectangle:
        page.graphics.drawRectangle(bounds: bounds, pen: pen);
      case PdfDrawingTool.circle:
        page.graphics.drawEllipse(bounds, pen: pen);
    }
  }
}

class PdfDrawingPage extends StatefulWidget {
  const PdfDrawingPage({
    super.key,
    required this.previewBytes,
    required this.pageSize,
    required this.pageNumber,
  });
  final Uint8List previewBytes;
  final Size pageSize;
  final int pageNumber;
  @override
  State<PdfDrawingPage> createState() => _PdfDrawingPageState();
}

class _PdfDrawingPageState extends State<PdfDrawingPage> {
  final List<PdfDrawing> drawings = [];
  PdfDrawing? current;
  PdfDrawingTool tool = PdfDrawingTool.pencil;
  Color color = Colors.red;
  double width = 2;
  bool ready = false;
  String? error;

  Offset pagePoint(Offset position, Size size) => Offset(
    (position.dx / size.width).clamp(0.0, 1.0) * widget.pageSize.width,
    (position.dy / size.height).clamp(0.0, 1.0) * widget.pageSize.height,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Draw on page ${widget.pageNumber}'),
      actions: [
        IconButton(
          tooltip: 'Undo',
          icon: const Icon(Icons.undo),
          onPressed: drawings.isEmpty
              ? null
              : () => setState(() => drawings.removeLast()),
        ),
        TextButton(
          onPressed: ready ? () => Navigator.pop(context, drawings) : null,
          child: const Text('Done'),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            children: [
              for (final value in PdfDrawingTool.values)
                ChoiceChip(
                  label: Text(value.name),
                  selected: tool == value,
                  onSelected: (_) => setState(() => tool = value),
                ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final value in [
              Colors.red,
              Colors.blue,
              Colors.black,
              Colors.green,
            ])
              IconButton(
                tooltip: 'Drawing color',
                onPressed: () => setState(() => color = value),
                icon: Icon(
                  color == value ? Icons.check_circle : Icons.circle,
                  color: value,
                ),
              ),
            DropdownButton<double>(
              value: width,
              items: [1.0, 2.0, 4.0, 6.0]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text('${value.toInt()} pt'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => width = value!),
            ),
          ],
        ),
        const Text(
          'Drag to draw. Done applies your drawings; Back discards them.',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: AspectRatio(
                aspectRatio: widget.pageSize.aspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        IgnorePointer(
                          child: SfPdfViewer.memory(
                            widget.previewBytes,
                            pageLayoutMode: PdfPageLayoutMode.single,
                            pageSpacing: 0,
                            enableTextSelection: false,
                            canShowScrollHead: false,
                            canShowScrollStatus: false,
                            enableDoubleTapZooming: false,
                            onDocumentLoaded: (_) =>
                                setState(() => ready = true),
                            onDocumentLoadFailed: (details) =>
                                setState(() => error = details.description),
                          ),
                        ),
                        if (ready)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) => setState(() {
                              current = PdfDrawing(tool, color, width, [
                                pagePoint(details.localPosition, size),
                              ]);
                            }),
                            onPanUpdate: (details) => setState(() {
                              final point = pagePoint(
                                details.localPosition,
                                size,
                              );
                              if (current?.tool == PdfDrawingTool.pencil ||
                                  current!.points.length == 1) {
                                current!.points.add(point);
                              } else {
                                current!.points[1] = point;
                              }
                            }),
                            onPanEnd: (_) => setState(() {
                              if (current != null) drawings.add(current!);
                              current = null;
                            }),
                            onPanCancel: () => setState(() => current = null),
                            child: CustomPaint(
                              painter: _DrawingPainter([
                                ...drawings,
                                ?current,
                              ], widget.pageSize),
                            ),
                          ),
                        if (!ready)
                          Center(
                            child: error != null
                                ? Text(error!)
                                : const CircularProgressIndicator(),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter(this.drawings, this.pageSize);
  final List<PdfDrawing> drawings;
  final Size pageSize;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / pageSize.width, size.height / pageSize.height);
    for (final drawing in drawings) {
      final paint = Paint()
        ..color = drawing.color
        ..strokeWidth = drawing.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final bounds = Rect.fromPoints(drawing.points.first, drawing.points.last);
      switch (drawing.tool) {
        case PdfDrawingTool.pencil:
          if (drawing.points.length == 1) {
            canvas.drawCircle(
              drawing.points.first,
              drawing.width / 2,
              Paint()..color = drawing.color,
            );
          } else {
            final path = Path()
              ..moveTo(drawing.points.first.dx, drawing.points.first.dy);
            for (final point in drawing.points.skip(1)) {
              path.lineTo(point.dx, point.dy);
            }
            canvas.drawPath(path, paint);
          }
        case PdfDrawingTool.rectangle:
          canvas.drawRect(bounds, paint);
        case PdfDrawingTool.circle:
          canvas.drawOval(bounds, paint);
        case PdfDrawingTool.line:
          canvas.drawLine(drawing.points.first, drawing.points.last, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
