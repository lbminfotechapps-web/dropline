import 'dart:typed_data';
import 'dart:ui';

import 'package:dropline/model/pdf_export.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test(
    'Export flattens highlights while preserving other annotations',
    () async {
      final source = PdfDocument();
      final page = source.pages.add();
      page.graphics.drawString(
        'Highlighted text',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: const Rect.fromLTWH(20, 20, 120, 20),
      );
      page.annotations.add(
        PdfTextMarkupAnnotation(
          const Rect.fromLTWH(20, 20, 120, 20),
          'Highlight',
          PdfColor(255, 255, 0),
          setAppearance: true,
          textMarkupAnnotationType: PdfTextMarkupAnnotationType.highlight,
        ),
      );
      page.annotations.add(
        PdfRectangleAnnotation(
          const Rect.fromLTWH(20, 60, 120, 20),
          'Keep editable',
          setAppearance: true,
        ),
      );
      final sourceBytes = Uint8List.fromList(await source.save());
      source.dispose();

      final result = PdfDocument(
        inputBytes: await flattenPdfHighlights(sourceBytes),
      );
      try {
        expect(result.pages[0].annotations.count, 1);
        expect(result.pages[0].annotations[0], isA<PdfRectangleAnnotation>());
        expect(
          PdfTextExtractor(result).extractText(),
          contains('Highlighted text'),
        );
      } finally {
        result.dispose();
      }
    },
  );
}
