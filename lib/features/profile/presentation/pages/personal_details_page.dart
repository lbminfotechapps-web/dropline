import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// ===========================================
// PERSONAL DETAILS DATA MODEL
// ===========================================

// ===========================================
// PERSONAL DETAILS PAGE
// ===========================================

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _phoneController = TextEditingController();
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _companyController = TextEditingController();

  late final TextEditingController _address1Controller =
      TextEditingController();
  late final TextEditingController _address2Controller =
      TextEditingController();
  late final TextEditingController _cityController = TextEditingController();
  late final TextEditingController _regionController = TextEditingController();
  late final TextEditingController _postalController = TextEditingController();

  String _language = '';
  String _phoneCountryCode = 'GB';
  String _addressCountry = '';
  String _photoPath = '';

  bool _addressExpanded = false;
  bool _hasChanges = false;

  final _imagePicker = ImagePicker();

  static const _languages = [
    'English',
    'Hindi',
    'Marathi',
    'Gujarati',
    'Tamil',
    'Other',
  ];

  // Replace these sample choices with your actual
  // supported countries or backend country list.
  static const _countries = [
    'United Kingdom',
    'India',
    'United States',
    'Canada',
    'Australia',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  // ===========================================
  // SELECT PROFILE PHOTO
  // ===========================================

  Future<void> _pickPhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 900,
      );

      if (!mounted || image == null) return;

      setState(() {
        _photoPath = image.path;
        _hasChanges = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select profile photo.')),
      );
    }
  }

  // ===========================================
  // SAVE DETAILS
  // ===========================================

  void _saveDetails() {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      setState(() => _addressExpanded = true);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(title: 'Personal details'),
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfilePhoto(),

                      const SizedBox(height: 25),

                      _buildInput(
                        label: 'Full name',
                        hint: 'Your full name',
                        controller: _nameController,
                        requiredField: true,
                        capitalized: true,
                      ),

                      _buildInput(
                        label: 'Contact number',
                        hint: 'Your contact number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: CountryCodePicker(
                          initialSelection: _phoneCountryCode,
                          favorite: const ['GB', 'IN', 'US'],
                          showDropDownButton: true,
                          flagWidth: 22,
                          padding: const EdgeInsets.only(left: 8),
                          textStyle: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          dialogBackgroundColor: AppColors.surface,
                          dialogTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          searchStyle: const TextStyle(color: Colors.white),
                          headerTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          closeIcon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          searchDecoration: const InputDecoration(
                            hintText: 'Search country or code',
                            hintStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.search, color: Colors.white),
                          ),
                          onChanged: (country) {
                            final code = country.code;
                            if (code == null || code == _phoneCountryCode)
                              return;
                            setState(() {
                              _phoneCountryCode = code;
                              _hasChanges = true;
                            });
                          },
                        ),
                        requiredField: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                          LengthLimitingTextInputFormatter(20),
                        ],
                      ),

                      _buildInput(
                        label: 'Email address (optional)',
                        hint: 'name@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validateEmail: true,
                      ),

                      _buildInput(
                        label: 'Company / employer (optional)',
                        hint: 'Add company',
                        controller: _companyController,
                        capitalized: true,
                      ),

                      _buildDropdown(
                        label: 'Preferred language',
                        hint: 'Select language',
                        value: _language,
                        options: _languages,
                        onChanged: (value) {
                          setState(() {
                            _language = value;
                            _hasChanges = true;
                          });
                        },
                      ),

                      const SizedBox(height: 18),

                      _buildAddressSection(),
                    ],
                  ),
                ),
              ),

              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================
  // PROFILE PHOTO
  // ===========================================

  Widget _buildProfilePhoto() {
    return InkWell(
      onTap: _pickPhoto,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Container(
            height: 76,
            width: 76,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: _photoPath != null
                ? Image.file(
                    File(_photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.iconColor,
                      size: 38,
                    ),
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.iconColor,
                    size: 38,
                  ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Add photo (optional)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // REUSABLE TEXT FIELD
  // ===========================================

  Widget _buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = false,
    bool validateEmail = false,
    bool capitalized = false,
    Widget? prefixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: capitalized
                ? TextCapitalization.words
                : TextCapitalization.none,
            onChanged: (_) => _markChanged(),
            cursorColor: AppColors.primary,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            validator: (value) {
              final text = (value ?? '').trim();

              if (requiredField && text.isEmpty) {
                return 'Please enter $label';
              }

              if (validateEmail && text.isNotEmpty) {
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                if (!emailRegex.hasMatch(text)) {
                  return 'Please enter a valid email address';
                }
              }

              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon,
              hintStyle: const TextStyle(
                color: AppColors.hintText,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // REUSABLE DROPDOWN
  // ===========================================

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value.isEmpty || !options.contains(value) ? null : value,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            hint: Text(
              hint,
              style: const TextStyle(color: AppColors.hintText, fontSize: 13),
            ),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (selected) {
              if (selected != null) onChanged(selected);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // EXPANDABLE ADDRESS
  // ===========================================

  Widget _buildAddressSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _addressExpanded = !_addressExpanded;
              });
            },
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Address',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _addressExpanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_addressExpanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInput(
                    label: 'Address line 1',
                    hint: 'House number and street',
                    controller: _address1Controller,
                  ),
                  _buildInput(
                    label: 'Address line 2 (optional)',
                    hint: 'Building, flat or locality',
                    controller: _address2Controller,
                  ),
                  _buildInput(
                    label: 'Town / City',
                    hint: 'Enter town or city',
                    controller: _cityController,
                  ),
                  _buildInput(
                    label: 'State / County / Region',
                    hint: 'Enter state, county or region',
                    controller: _regionController,
                  ),
                  _buildInput(
                    label: 'Postcode / ZIP / PIN code',
                    hint: 'Enter postal code',
                    controller: _postalController,
                    keyboardType: TextInputType.text,
                  ),
                  _buildDropdown(
                    label: 'Address country',
                    hint: 'Select address country',
                    value: _addressCountry,
                    options: _countries,
                    onChanged: (selected) {
                      setState(() {
                        _addressCountry = selected;
                        _hasChanges = true;
                      });
                    },
                  ),
                  const Text(
                    'Your address country can differ '
                    'from your country of work.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================
  // STICKY SAVE BUTTON
  // ===========================================

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: 51,
        child: ElevatedButton(
          onPressed: _hasChanges ? _saveDetails : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryText,
            disabledBackgroundColor: AppColors.disabledButton,
            disabledForegroundColor: AppColors.disabledText,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: const Text(
            'Save changes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
