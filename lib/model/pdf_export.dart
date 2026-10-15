import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Embeds highlight appearances into exported pages for reader compatibility.
/// Other annotations, including links, remain interactive.
Future<Uint8List> flattenPdfHighlights(Uint8List sourceBytes) async {
  final document = PdfDocument(inputBytes: sourceBytes);
  try {
    for (int pageIndex = 0; pageIndex < document.pages.count; pageIndex++) {
      final annotations = document.pages[pageIndex].annotations;
      for (int index = 0; index < annotations.count; index++) {
        final annotation = annotations[index];
        if (annotation is PdfTextMarkupAnnotation &&
            annotation.textMarkupAnnotationType ==
                PdfTextMarkupAnnotationType.highlight) {
          annotation.setAppearance = true;
          annotation.flatten();
        }
      }
    }
    return Uint8List.fromList(await document.save());
  } finally {
    document.dispose();
  }
}
