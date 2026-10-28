import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PrescriptionReaderPage extends StatefulWidget {
  const PrescriptionReaderPage({super.key});

  @override
  State<PrescriptionReaderPage> createState() => _PrescriptionReaderPageState();
}

class _PrescriptionReaderPageState extends State<PrescriptionReaderPage> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  final TextEditingController _textController = TextEditingController();

  XFile? _selectedImage;
  bool _isProcessing = false;
  bool _isSelecting = false;
  bool get _isBusy => _isProcessing || _isSelecting;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    if (_isBusy) return;

    setState(() => _isSelecting = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image == null || !mounted) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Prescription',
            toolbarColor: const Color(0xFF2563EB),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Prescription',
            doneButtonTitle: 'Crop & Read',
            aspectRatioLockEnabled: false,
          ),
        ],
      );
      if (cropped == null || !mounted) return;

      setState(() {
        _selectedImage = XFile(cropped.path);
        _textController.clear();
        _errorMessage = null;
      });

      await _recognizeText(cropped.path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to select image: $e';
      });
    } finally {
      if (mounted) setState(() => _isSelecting = false);
    }
  }

  Future<void> _recognizeText(String imagePath) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final inputImage = InputImage.fromFilePath(imagePath);

      final RecognizedText result = await _textRecognizer.processImage(
        inputImage,
      );

      if (!mounted) return;

      // Group fragments on the same row, then read rows top to bottom.
      final lines = result.blocks.expand((block) => block.lines).toList()
        ..sort(
          (a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy),
        );
      final rows = <List<TextLine>>[];
      for (final line in lines) {
        if (rows.isEmpty) {
          rows.add([line]);
          continue;
        }
        final anchor = rows.last.first.boundingBox;
        final box = line.boundingBox;
        final tolerance =
            (anchor.height < box.height ? anchor.height : box.height) * 0.5;
        if ((box.center.dy - anchor.center.dy).abs() <= tolerance) {
          rows.last.add(line);
        } else {
          rows.add([line]);
        }
      }
      final extractedText = rows
          .map((row) {
            row.sort(
              (a, b) => a.boundingBox.left.compareTo(b.boundingBox.left),
            );
            return row.map((line) => line.text).join(' ');
          })
          .join('\n')
          .trim();

      setState(() {
        _textController.text = extractedText;

        if (extractedText.isEmpty) {
          _errorMessage = 'No text detected. Try capturing a clearer image.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to recognize text: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _clearData() {
    if (_isBusy) return;

    setState(() {
      _selectedImage = null;
      _textController.clear();
      _errorMessage = null;
    });
  }

  void _saveText() {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No prescription text to save')),
      );
      return;
    }

    // TODO: Save to your local database or send to your API.
    // Example: context.pop(text);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Text is ready to save')));
  }

  @override
  void dispose() {
    _textController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Prescription Reader',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            onPressed: _isBusy ? null : _clearData,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan Prescription',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18253D),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Capture or select an image, crop it, then read the text.',
                      style: TextStyle(color: Color(0xFF788397), fontSize: 13),
                    ),
                    const SizedBox(height: 18),

                    // IMAGE PREVIEW
                    Container(
                      width: double.infinity,
                      height: 225,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE0E6F0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _selectedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.document_scanner_outlined,
                                  size: 55,
                                  color: Color(0xFF8C9CB8),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No prescription selected',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4B5872),
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Take a photo or choose from gallery',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )
                          : Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Center(
                                child: Text('Unable to display image'),
                              ),
                            ),
                    ),

                    const SizedBox(height: 14),

                    // CAMERA AND GALLERY BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: _sourceButton(
                            title: 'Camera',
                            icon: Icons.camera_alt_outlined,
                            onTap: _isBusy
                                ? null
                                : () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _sourceButton(
                            title: 'Gallery',
                            icon: Icons.photo_library_outlined,
                            onTap: _isBusy
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    if (_isProcessing) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Reading prescription text...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],

                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0EF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFB3261E),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],

                    // EXTRACTED TEXT FIELD
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Extracted Text',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18253D),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isBusy || _selectedImage == null
                              ? null
                              : () => _recognizeText(_selectedImage!.path),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Re-scan'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E6F0)),
                      ),
                      child: TextField(
                        readOnly: _isBusy,
                        controller: _textController,
                        minLines: 8,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF26364D),
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              'Recognized prescription text will appear here...',
                          hintStyle: TextStyle(color: Color(0xFF9CA6B6)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Please verify medicine names, dosage and '
                            'instructions manually. Handwriting recognition '
                            'may contain errors.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: Color(0xFF788397),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // FIXED BOTTOM BUTTON
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE9EDF3))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _saveText,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Use Extracted Text',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFDCE5F3)),
      ),
    );
  }
}
