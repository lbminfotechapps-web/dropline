
import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class AddAreaBottomSheet extends StatefulWidget {
  final String title;
  final String description;
  final String hintText;
  final String buttonText;
  final String? parentName;

  final Future<bool> Function(String name) onSave;
  final String? Function()? errorMessage;

  const AddAreaBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.hintText,
    required this.buttonText,
    required this.onSave,
    this.parentName,
    this.errorMessage,
  });

  @override
  State<AddAreaBottomSheet> createState() =>
      _AddAreaBottomSheetState();
}

class _AddAreaBottomSheetState
    extends State<AddAreaBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  bool _isSaving = false;
  String? _saveError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    bool success = false;

    try {
      success = await widget.onSave(
        _nameController.text.trim(),
      );
    } catch (e) {
      _saveError = e.toString();
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSaving = false;
      _saveError = widget.errorMessage?.call() ??
          _saveError ??
          'Unable to save. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF293448),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(34),
          ),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.13),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24, 12, 24, 35,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Bottom sheet drag indicator
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted
                            .withValues(alpha: 0.65),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: AppTextStyles.headingSmall
                              .copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.white
                              .withValues(alpha: 0.10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                            side: BorderSide(
                              color: AppColors.white
                                  .withValues(alpha: 0.20),
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    widget.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  if (widget.parentName != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Adding under',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.parentName!,
                      style: AppTextStyles.titleSmall,
                    ),
                  ],

                  const SizedBox(height: 26),

                  Text(
                    'Name',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 9),

                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    enabled: !_isSaving,
                    textCapitalization:
                        TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: AppTextStyles.inputHint,
                      filled: true,
                      fillColor: const Color(0xFF1B2535),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.white,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.white,
                          width: 1.3,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.white,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      if (value.trim().length > 100) {
                        return 'Maximum 100 characters allowed';
                      }
                      return null;
                    },
                  ),

                  if (_saveError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _saveError!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFF5F6F8),
                        foregroundColor:
                            const Color(0xFF152033),
                        disabledBackgroundColor:
                            const Color(0xFFAFB5BD),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF152033),
                              ),
                            )
                          : Text(
                              widget.buttonText,
                              style:
                                  AppTextStyles.buttonMedium
                                      .copyWith(
                                color: const Color(0xFF152033),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
