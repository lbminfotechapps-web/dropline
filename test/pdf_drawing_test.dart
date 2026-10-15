import 'dart:typed_data';
import 'package:dropline/features/pdf_drawing_page.dart';
import 'package:dropline/model/pdf_export.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf;

void main() {
  test('All drawing tools survive export with existing page content', () async {
    final source = pdf.PdfDocument();
    final page = source.pages.add();
    page.graphics.drawString(
      'Original text',
      pdf.PdfStandardFont(pdf.PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(20, 20, 150, 20),
    );
    final before = await source.save();
    paintPdfDrawings(page, [
      for (final tool in PdfDrawingTool.values)
        PdfDrawing(tool, Colors.red, 2, [
          const Offset(50, 80),
          const Offset(100, 120),
          const Offset(140, 100),
        ]),
      PdfDrawing(PdfDrawingTool.pencil, Colors.blue, 4, [const Offset(20, 80)]),
    ]);
    final drawnBytes = Uint8List.fromList(await source.save());
    source.dispose();
    expect(drawnBytes.length, greaterThan(before.length));
    final exported = pdf.PdfDocument(
      inputBytes: await flattenPdfHighlights(drawnBytes),
    );
    try {
      expect(exported.pages.count, 1);
      expect(
        pdf.PdfTextExtractor(exported).extractText(),
        contains('Original text'),
      );
    } finally {
      exported.dispose();
    }
  });
}
