import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CertificateFormData {
  final String name;
  final String issuedBy;
  final String documentName;
  final String documentPath;
  final DateTime? expiryDate;
  final bool noExpiry;

  const CertificateFormData({
    required this.name,
    required this.issuedBy,
    required this.documentName,
    required this.documentPath,
    required this.expiryDate,
    required this.noExpiry,
  });
}

class AddCertificateScreen extends StatefulWidget {
  const AddCertificateScreen({super.key});

  @override
  State<AddCertificateScreen> createState() => _AddCertificateScreenState();
}

class _AddCertificateScreenState extends State<AddCertificateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _issuedByController = TextEditingController();

  final _imagePicker = ImagePicker();

  String? _documentName;
  String? _documentPath;

  DateTime? _expiryDate;
  bool _noExpiry = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _issuedByController.dispose();
    super.dispose();
  }

  // ==================================================
  // FILE PICKER
  // ==================================================

  Future<void> _chooseFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (!mounted || file == null) return;

      if (file.path == null) {
        _showMessage('Unable to access selected file.');
        return;
      }

      setState(() {
        _documentName = file.name;
        _documentPath = file.path;
      });
    } catch (e) {
      _showMessage('Unable to select document: $e');
    }
  }

  // ==================================================
  // IMAGE PICKER
  // ==================================================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );

      if (!mounted || image == null) return;

      setState(() {
        _documentName = image.name;
        _documentPath = image.path;
      });
    } catch (e) {
      _showMessage('Unable to select photo: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ==================================================
  // DOCUMENT BOTTOM SHEET
  // ==================================================

  void _showDocumentBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.sheetBackground,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.viewPaddingOf(sheetContext).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),

              const SizedBox(height: 20),

              const Text(
                'Add document',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 22),

              _documentOption(
                icon: Icons.folder_open_rounded,
                title: 'Choose file',
                subtitle: 'Browse PDFs and documents',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _chooseFile();
                },
              ),

              const SizedBox(height: 10),

              _documentOption(
                icon: Icons.image_outlined,
                title: 'Choose photo',
                subtitle: 'Select from your photos',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),

              const SizedBox(height: 10),

              _documentOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take photo',
                subtitle: 'Use your camera',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),

              const SizedBox(height: 18),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _documentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 26, color: AppColors.iconColor),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================
  // CALENDAR BOTTOM SHEET
  // ==================================================

  Future<void> _showExpiryDatePicker() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDate = today;
    final lastDate = DateTime(today.year + 30, 12, 31);

    DateTime tempDate = _expiryDate != null && !_expiryDate!.isBefore(today)
        ? _expiryDate!
        : today;

    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, updateSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                MediaQuery.viewPaddingOf(context).bottom + 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSheetHandle(),

                  const SizedBox(height: 16),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Select expiry date',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.primary,
                        onPrimary: AppColors.primaryText,
                        surface: AppColors.sheetBackground,
                        onSurface: AppColors.textPrimary,
                      ),
                      datePickerTheme: const DatePickerThemeData(
                        backgroundColor: AppColors.sheetBackground,
                        headerForegroundColor: AppColors.textPrimary,
                        weekdayStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        dayStyle: TextStyle(color: AppColors.textPrimary),
                        yearStyle: TextStyle(color: AppColors.textPrimary),
                        todayForegroundColor: WidgetStatePropertyAll(
                          AppColors.primary,
                        ),
                        todayBorder: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: tempDate,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      onDateChanged: (value) {
                        updateSheet(() {
                          tempDate = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext, tempDate);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text(
                        'Confirm date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      _expiryDate = selected;
    });
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.sheetHandle,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ==================================================
  // SAVE CERTIFICATE
  // ==================================================

  void _saveCertificate() {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_documentPath == null) {
      _showMessage('Please add a document.');
      return;
    }

    if (!_noExpiry && _expiryDate == null) {
      _showMessage('Please select expiry date.');
      return;
    }

    setState(() {
      _saving = true;
    });

    final certificate = CertificateFormData(
      name: _nameController.text.trim(),
      issuedBy: _issuedByController.text.trim(),
      documentName: _documentName!,
      documentPath: _documentPath!,
      expiryDate: _noExpiry ? null : _expiryDate,
      noExpiry: _noExpiry,
    );

    // Return data to the previous screen.
    // Upload the document and save details through
    // your API before treating it as persisted.
    Navigator.pop(context, certificate);
  }

  // ==================================================
  // COMMON INPUT
  // ==================================================

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: AppColors.primary),
        errorBorder: _inputBorder(color: AppColors.error),
      ),
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter certificate name';
              }
              return null;
            }
          : null,
    );
  }

  OutlineInputBorder _inputBorder({Color color = AppColors.border}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: color),
    );
  }

  // ==================================================
  // DOCUMENT PICKER FIELD
  // ==================================================

  Widget _buildDocumentField() {
    final hasDocument = _documentPath != null;

    return InkWell(
      onTap: _showDocumentBottomSheet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              hasDocument
                  ? Icons.description_outlined
                  : Icons.file_upload_outlined,
              size: 28,
              color: AppColors.iconColor,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDocument ? _documentName! : 'Add document',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasDocument
                        ? 'Tap to change document'
                        : 'PDF, photo or camera',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            if (hasDocument)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // EXPIRY FIELD
  // ==================================================

  Widget _buildExpiryField() {
    return InkWell(
      onTap: _noExpiry ? null : _showExpiryDatePicker,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _noExpiry
                    ? 'No expiry'
                    : _expiryDate == null
                    ? 'Select date'
                    : DateFormat('dd MMM yyyy').format(_expiryDate!),
                style: TextStyle(
                  color: _expiryDate != null && !_noExpiry
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.iconColor,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // NO EXPIRY SWITCH
  // ==================================================

  Widget _buildNoExpirySwitch() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'No expiry',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: _noExpiry,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.border,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.disabledButton,
            onChanged: (value) {
              setState(() {
                _noExpiry = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ==================================================
  // SAVE BUTTON
  // ==================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _saveCertificate,
        icon: const Icon(Icons.check_rounded, size: 21),
        label: const Text(
          'Save certificate',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryText,
          disabledBackgroundColor: AppColors.disabledButton,
          disabledForegroundColor: AppColors.disabledText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ==================================================
  // BUILD SCREEN
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(title: 'Add certificate'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    _buildLabel('Certificate name'),

                    _buildTextField(
                      controller: _nameController,
                      hint: 'e.g. Site safety training',
                      requiredField: true,
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('Issued by (optional)'),

                    _buildTextField(
                      controller: _issuedByController,
                      hint: 'Add issuing organisation',
                    ),

                    const SizedBox(height: 20),

                    _buildLabel('Document'),

                    _buildDocumentField(),

                    const SizedBox(height: 20),

                    _buildLabel('Expiry date'),

                    _buildExpiryField(),

                    const SizedBox(height: 14),

                    _buildNoExpirySwitch(),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildSaveButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
