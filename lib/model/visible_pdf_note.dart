import 'dart:ui';

class VisiblePdfNote {
  final int pageNumber;
  final Rect selectedBounds;
  final String text;

  VisiblePdfNote({
    required this.pageNumber,
    required this.selectedBounds,
    required this.text,
  });
}
