import 'dart:typed_data';

import 'package:dropline/core/utility/widgets/app_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../model/pdf_export.dart';
import 'pdf_drawing_page.dart';

class PdfEditorPage extends StatefulWidget {
  const PdfEditorPage({
    super.key,
    this.initialBytes,
    this.fileName,
    this.onSave,
  });

  final Uint8List? initialBytes;
  final String? fileName;
  final Future<void> Function(Uint8List bytes)? onSave;

  @override
  State<PdfEditorPage> createState() => _PdfEditorPageState();
}

class _PdfEditorPageState extends State<PdfEditorPage> {
  final PdfViewerController controller = PdfViewerController();

  // Keep one viewer state attached to the controller. The viewer reloads when
  // its bytes change; replacing its key can briefly attach two viewer states.
  final GlobalKey<SfPdfViewerState> pdfKey = GlobalKey<SfPdfViewerState>();

  Uint8List? currentPdfBytes;
  String? selectedFileName;

  bool isLoading = false;
  bool isSaving = false;
  bool isAddingNote = false;
  bool isDrawing = false;
  int? pendingPageNumber;

  bool get hasPdf => currentPdfBytes != null;

  @override
  void initState() {
    super.initState();
    currentPdfBytes = widget.initialBytes;
    selectedFileName = widget.fileName;
  }

  // =========================================
  // SHOW MESSAGE
  // =========================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =========================================
  // OPEN PDF
  // =========================================

  Future<void> openPdf() async {
    if (isLoading || isSaving || isAddingNote || isDrawing) return;

    try {
      final PlatformFile? pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (!mounted || pickedFile == null) return;

      setState(() => isLoading = true);

      final Uint8List bytes = await pickedFile.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('Selected PDF is empty');
      }

      if (!mounted) return;

      controller.annotationMode = PdfAnnotationMode.none;
      controller.clearSelection();

      setState(() {
        currentPdfBytes = bytes;
        selectedFileName = pickedFile.name;
      });

      showMessage('PDF opened successfully');
    } catch (e) {
      showMessage('Unable to open PDF: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // =========================================
  // HIGHLIGHT SELECTED TEXT
  // =========================================

  void highlightText() {
    if (!hasPdf) {
      showMessage('Please open a PDF first');
      return;
    }

    if (isAddingNote || isSaving || isLoading || isDrawing) return;

    final List<PdfTextLine>? selectedLines = pdfKey.currentState
        ?.getSelectedTextLines();

    if (selectedLines == null || selectedLines.isEmpty) {
      showMessage('Long press and select text first');
      return;
    }

    final annotation = HighlightAnnotation(textBoundsCollection: selectedLines);

    annotation.color = Colors.yellow;

    controller.addAnnotation(annotation);
    controller.clearSelection();

    showMessage('Text highlighted successfully');
  }

  // =========================================
  // ADD VISIBLE TEXT NOTE
  // =========================================

  Future<void> addNote() async {
    if (!hasPdf) {
      showMessage('Please open a PDF first');
      return;
    }

    if (isAddingNote || isSaving || isLoading || isDrawing) return;

    final List<PdfTextLine>? selectedLines = pdfKey.currentState
        ?.getSelectedTextLines();

    if (selectedLines == null || selectedLines.isEmpty) {
      showMessage('Long press and select text first');
      return;
    }

    final PdfTextLine selectedLine = selectedLines.first;

    final int pageNumber = selectedLine.pageNumber;
    final Rect selectedBounds = selectedLine.bounds;

    // Remove the viewer's selection overlay before the dialog takes focus.
    controller.clearSelection();
    controller.annotationMode = PdfAnnotationMode.none;

    // Dialog manages its own TextEditingController
    final String? noteText = await showDialog<String>(
      context: context,
      builder: (context) => const _AddPdfNoteDialog(),
    );

    if (!mounted || noteText == null || noteText.trim().isEmpty) {
      return;
    }

    setState(() {
      isAddingNote = true;
    });

    try {
      final List<int> savedBytes = await controller.saveDocument();

      final Uint8List sourceBytes = Uint8List.fromList(savedBytes);

      final Uint8List modifiedBytes = await drawVisibleNote(
        sourceBytes: sourceBytes,
        pageNumber: pageNumber,
        selectedBounds: selectedBounds,
        noteText: noteText.trim(),
      );

      if (!mounted) return;

      controller.clearSelection();
      controller.annotationMode = PdfAnnotationMode.none;

      setState(() {
        currentPdfBytes = modifiedBytes;
      });

      showMessage('Visible note added successfully');
    } catch (e) {
      showMessage('Failed to add note: $e');
    } finally {
      if (mounted) {
        setState(() {
          isAddingNote = false;
        });
      }
    }
  }

  Future<void> drawOnPage() async {
    if (!hasPdf || isLoading || isSaving || isAddingNote || isDrawing) return;
    final pageNumber = controller.pageNumber;
    if (pageNumber < 1) return;
    controller.clearSelection();
    controller.annotationMode = PdfAnnotationMode.none;
    setState(() => isDrawing = true);
    pdf.PdfDocument? document;
    pdf.PdfDocument? preview;
    try {
      document = pdf.PdfDocument(inputBytes: await controller.saveDocument());
      final page = document.pages[pageNumber - 1];
      final pageSize = page.getClientSize();
      preview = pdf.PdfDocument();
      preview.pageSettings.size = pageSize;
      preview.pageSettings.margins.all = 0;
      preview.pages.add().graphics.drawPdfTemplate(
        page.createTemplate(),
        Offset.zero,
        pageSize,
      );
      final previewBytes = Uint8List.fromList(await preview.save());
      if (!mounted) return;
      final drawings = await Navigator.of(context).push<List<PdfDrawing>>(
        MaterialPageRoute(
          builder: (_) => PdfDrawingPage(
            previewBytes: previewBytes,
            pageSize: pageSize,
            pageNumber: pageNumber,
          ),
        ),
      );
      if (!mounted || drawings == null || drawings.isEmpty) return;
      paintPdfDrawings(page, drawings);
      final bytes = Uint8List.fromList(await document.save());
      if (!mounted) return;
      setState(() {
        pendingPageNumber = pageNumber;
        currentPdfBytes = bytes;
      });
      showMessage('Drawings applied. Use Save As to export the PDF.');
    } catch (e) {
      showMessage('Unable to draw on PDF: $e');
    } finally {
      preview?.dispose();
      document?.dispose();
      if (mounted) setState(() => isDrawing = false);
    }
  }

  // =========================================
  // DRAW VISIBLE NOTE INTO PDF
  // =========================================

  Future<Uint8List> drawVisibleNote({
    required Uint8List sourceBytes,
    required int pageNumber,
    required Rect selectedBounds,
    required String noteText,
  }) async {
    final pdf.PdfDocument document = pdf.PdfDocument(inputBytes: sourceBytes);

    try {
      final int pageIndex = pageNumber - 1;

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        throw Exception('Invalid PDF page number');
      }

      final pdf.PdfPage page = document.pages[pageIndex];

      final Size pageSize = page.getClientSize();

      // Yellow box size
      final double boxWidth = pageSize.width < 240
          ? pageSize.width * 0.85
          : 230.0;

      // Estimate note height from text length
      final int approxCharsPerLine = (boxWidth / 6).floor().clamp(12, 50);

      int estimatedLines = 0;

      for (final line in noteText.split('\n')) {
        estimatedLines += (line.length / approxCharsPerLine).ceil().clamp(
          1,
          100,
        );
      }

      final double estimatedHeight = 32.0 + estimatedLines * 15.0;

      final double boxHeight = estimatedHeight.clamp(65.0, 190.0);

      // Position note below selected text
      double x = selectedBounds.left;
      double y = selectedBounds.bottom + 8;

      // Keep note within page
      x = x.clamp(0.0, (pageSize.width - boxWidth).clamp(0.0, pageSize.width));

      y = y.clamp(
        0.0,
        (pageSize.height - boxHeight).clamp(0.0, pageSize.height),
      );

      final Rect noteRect = Rect.fromLTWH(x, y, boxWidth, boxHeight);

      // Note background
      page.graphics.drawRectangle(
        bounds: noteRect,
        brush: pdf.PdfSolidBrush(pdf.PdfColor(255, 247, 190)),
        pen: pdf.PdfPen(pdf.PdfColor(220, 175, 55), width: 1),
      );

      // Note heading
      page.graphics.drawString(
        'NOTE',
        pdf.PdfStandardFont(
          pdf.PdfFontFamily.helvetica,
          10,
          style: pdf.PdfFontStyle.bold,
        ),
        brush: pdf.PdfSolidBrush(pdf.PdfColor(110, 75, 0)),
        bounds: Rect.fromLTWH(x + 8, y + 6, boxWidth - 16, 15),
      );

      // Note text
      page.graphics.drawString(
        noteText,
        pdf.PdfStandardFont(pdf.PdfFontFamily.helvetica, 10),
        brush: pdf.PdfBrushes.black,
        bounds: Rect.fromLTWH(x + 8, y + 24, boxWidth - 16, boxHeight - 30),
        format: pdf.PdfStringFormat(
          alignment: pdf.PdfTextAlignment.left,
          lineAlignment: pdf.PdfVerticalAlignment.top,
        ),
      );

      // Generate updated PDF
      final List<int> result = await document.save();

      return Uint8List.fromList(result);
    } finally {
      document.dispose();
    }
  }

  // =========================================
  // SAVE EDITED PDF TO PUBLIC STORAGE
  // =========================================

  Future<void> savePdf() async {
    if (!hasPdf || isSaving || isAddingNote || isLoading || isDrawing) {
      return;
    }

    setState(() => isSaving = true);

    try {
      // Save latest highlights and visible notes
      final List<int> outputBytes = await controller.saveDocument();

      final Uint8List bytes = await flattenPdfHighlights(
        Uint8List.fromList(outputBytes),
      );

      if (widget.onSave != null) {
        await widget.onSave!(bytes);
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      final String baseName = (selectedFileName ?? 'document').replaceAll(
        RegExp(r'\.pdf$', caseSensitive: false),
        '',
      );

      final String fileName =
          '${baseName}_edited_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Android public Save As / Documents provider
      final Uri? savedUri = await FilePicker.saveFile(
        dialogTitle: 'Save Edited PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (savedUri == null) {
        showMessage('Save cancelled');
        return;
      }

      debugPrint('PDF saved: $savedUri');

      showMessage('PDF saved successfully. Check your selected folder.');
    } catch (e) {
      debugPrint('PDF SAVE ERROR: $e');
      showMessage('Unable to save PDF: $e');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  // =========================================
  // REMOVE TEXT SELECTION
  // =========================================

  void clearSelection() {
    controller.clearSelection();
    controller.annotationMode = PdfAnnotationMode.none;
  }

  // =========================================
  // DISPOSE
  // =========================================

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // =========================================
  // EDITOR TOOL BUTTON
  // =========================================

  Widget editorButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================
  // TOOLBAR
  // =========================================

  Widget buildToolbar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                editorButton(
                  icon: Icons.pan_tool_alt,
                  label: 'Select',
                  color: const Color(0xFF176B4D),
                  onTap: hasPdf ? clearSelection : null,
                ),
                const SizedBox(width: 8),
                editorButton(
                  icon: Icons.draw,
                  label: 'Pencil / Shapes',
                  color: Colors.red.shade700,
                  onTap: hasPdf ? drawOnPage : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                editorButton(
                  icon: Icons.folder_open,
                  label: 'Open',
                  color: const Color(0xFF176B4D),
                  onTap: widget.onSave == null ? openPdf : null,
                ),
                const SizedBox(width: 8),
                editorButton(
                  icon: Icons.highlight,
                  label: 'Highlight',
                  color: Colors.orange.shade800,
                  onTap: hasPdf ? highlightText : null,
                ),
                const SizedBox(width: 8),
                editorButton(
                  icon: Icons.edit_note,
                  label: 'Add Note',
                  color: Colors.blue.shade700,
                  onTap: hasPdf ? addNote : null,
                ),
                const SizedBox(width: 8),
                editorButton(
                  icon: Icons.save_alt,
                  label: widget.onSave == null ? 'Save As' : 'Save',
                  color: const Color(0xFF176B4D),
                  onTap: hasPdf ? savePdf : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // EMPTY SCREEN
  // =========================================

  Widget buildEmptyScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F2EC),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                size: 65,
                color: Color(0xFF176B4D),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'PDF Editor',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Open any PDF to highlight text,\n'
              'add notes, draw with a pencil or shapes,\n'
              'and save changes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: openPdf,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF176B4D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // MAIN UI
  // =========================================

  @override
  Widget build(BuildContext context) {
    final bool busy = isSaving || isLoading || isAddingNote || isDrawing;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF176B4D),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PDF Editor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (selectedFileName != null)
              Text(
                selectedFileName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          if (hasPdf)
            IconButton(
              tooltip: 'Clear Selection',
              icon: const Icon(Icons.close),
              onPressed: busy ? null : clearSelection,
            ),
          if (hasPdf)
            IconButton(
              tooltip: 'Save PDF',
              icon: const Icon(Icons.save),
              onPressed: busy ? null : savePdf,
            ),
        ],
      ),
      body: Stack(
        children: [
          if (!hasPdf)
            buildEmptyScreen()
          else
            SfPdfViewer.memory(
              currentPdfBytes!,
              key: pdfKey,
              controller: controller,
              enableTextSelection: true,
              canShowTextSelectionMenu: true,
              onDocumentLoaded: (_) {
                if (pendingPageNumber != null) {
                  controller.jumpToPage(pendingPageNumber!);
                  pendingPageNumber = null;
                }
              },
              onDocumentLoadFailed: (details) {
                showMessage('PDF load failed: ${details.description}');
              },
            ),

          if (busy)
            Container(
              color: Colors.black.withValues(alpha: 0.20),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 14),
                        Text(
                          isSaving
                              ? 'Saving PDF...'
                              : isAddingNote
                              ? 'Adding visible note...'
                              : isDrawing
                              ? 'Preparing drawing page...'
                              : 'Opening PDF...',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: busy ? null : buildToolbar(),
    );
  }
}

class _AddPdfNoteDialog extends StatefulWidget {
  const _AddPdfNoteDialog();

  @override
  State<_AddPdfNoteDialog> createState() => _AddPdfNoteDialogState();
}

class _AddPdfNoteDialogState extends State<_AddPdfNoteDialog> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  void _submitNote() {
    final String note = _noteController.text.trim();

    if (note.isEmpty) {
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(const SnackBar(content: Text('Please enter a note')));
      AppToast.success('Please enter a note.');
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.edit_note, color: Color(0xFF176B4D)),
          SizedBox(width: 8),
          Text('Add Note'),
        ],
      ),
      content: TextField(
        controller: _noteController,
        autofocus: true,
        maxLines: 5,
        maxLength: 250,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Enter your note here...',
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xFFFFFBE6),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF176B4D),
            foregroundColor: Colors.white,
          ),
          onPressed: _submitNote,
          icon: const Icon(Icons.check),
          label: const Text('Add Note'),
        ),
      ],
    );
  }
}
