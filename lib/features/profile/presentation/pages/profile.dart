import 'package:country_code_picker/country_code_picker.dart';
import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:flutter/material.dart';

import 'package:dropline/core/theme/appcolors.dart';
import 'package:go_router/go_router.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  String? _country;
  String? _jobTitle;
  String _kinPhoneCountryCode = 'GB';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _kinNameController = TextEditingController();
  final _kinPhoneController = TextEditingController();
  final _kinRelationshipController = TextEditingController();

  bool _hasChanges = false;

  final List<String> _countries = [
    'United Kingdom',
    'India',
    'United States',
    'Canada',
    'Australia',
    'Other',
  ];

  final List<String> _jobs = [
    'Site Manager',
    'Supervisor',
    'Engineer',
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Labourer',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _kinNameController.dispose();
    _kinPhoneController.dispose();
    _kinRelationshipController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _showSelectionSheet({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.sheetBackground,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.sheetHandle,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = selected == option;

                      return Material(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            onSelected(option);
                            Navigator.pop(sheetContext);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 21,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDetailsSheet({
    required String title,
    required List<Widget> fields,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 100,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.sheetHandle,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                ...fields,
                const SizedBox(height: 16),
                SizedBox(
                  height: 49,
                  child: ElevatedButton(
                    onPressed: () {
                      _markChanged();
                      Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => _markChanged(),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.inputBackground,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  // void _openPersonalDetails() {
  //   _showDetailsSheet(
  //     title: 'Personal details',
  //     fields: [
  //       _inputField('Full name', _nameController),
  //       _inputField(
  //         'Email address',
  //         _emailController,
  //         keyboardType: TextInputType.emailAddress,
  //       ),
  //       _inputField(
  //         'Phone number',
  //         _phoneController,
  //         keyboardType: TextInputType.phone,
  //       ),
  //       _inputField('Address', _addressController),
  //     ],
  //   );
  // }

  // Future<void> _openPersonalDetails() async {

  //   if (!mounted || result == null) return;

  //   setState(() {
  //     _personalDetails = result;
  //     _hasChanges = true;
  //   });
  // }

  void _openNextOfKin() {
    _showDetailsSheet(
      title: 'Next of kin',
      fields: [
        _inputField('Full name', _kinNameController),
        _inputField('Relationship', _kinRelationshipController),
        _inputField(
          'Phone number',
          _kinPhoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: CountryCodePicker(
            initialSelection: _kinPhoneCountryCode,
            favorite: const ['GB', 'IN', 'US'],
            showDropDownButton: true,
            flagWidth: 22,
            padding: const EdgeInsets.only(left: 8),
            textStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            dialogBackgroundColor: AppColors.surface,
            dialogTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
            searchStyle: const TextStyle(color: Colors.white),
            headerTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            closeIcon: const Icon(Icons.close, color: Colors.white),
            searchDecoration: const InputDecoration(
              hintText: 'Search country or code',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.search, color: Colors.white),
            ),
            onChanged: (country) {
              final code = country.code;
              if (code == null || code == _kinPhoneCountryCode) return;
              setState(() {
                _kinPhoneCountryCode = code;
                _hasChanges = true;
              });
            },
          ),
        ),
      ],
    );
  }

  void _openHealthSupport() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 36,
              ),
              const SizedBox(height: 16),
              const Text(
                'Health & support',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This section is private. Health and '
                'support details can be added when the '
                'secure profile feature is available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() {
    if (!_hasChanges) return;

    // TODO: Connect your profile repository / BLoC here.
    // Do not clear _hasChanges until the API confirms success.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile changes are ready. Connect the save API.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Profile', showBackButton: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // _buildHeader(),
                      // const SizedBox(height: 23),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _profileCard(
                                title: 'Country of Work',
                                subtitle:
                                    _country ??
                                    'Choose where you will be working.',
                                icon: Icons.keyboard_arrow_down_rounded,
                                onTap: () => _showSelectionSheet(
                                  title: 'Country of Work',
                                  options: _countries,
                                  selected: _country,
                                  onSelected: (value) {
                                    setState(() {
                                      _country = value;
                                      _hasChanges = true;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              _profileCard(
                                title: 'Personal details',
                                subtitle: 'Name, contact and address',
                                icon: Icons.chevron_right_rounded,
                                onTap: () =>
                                    context.push(AppRouter.personalDetails),
                              ),

                              const SizedBox(height: 12),

                              _profileCard(
                                title: 'Next of kin',
                                subtitle: 'Name, relationship and phone',
                                icon: Icons.keyboard_arrow_down_rounded,
                                onTap: _openNextOfKin,
                              ),

                              const SizedBox(height: 12),

                              _profileCard(
                                title: 'Health & support',
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 15,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Private',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: _openHealthSupport,
                              ),

                              const SizedBox(height: 98),

                              _profileCard(
                                title: 'Job title / trade',
                                subtitle: _jobTitle ?? 'Select your role',
                                icon: Icons.keyboard_arrow_down_rounded,
                                // icon: Icons.chevron_right_rounded,
                                onTap: () => _showSelectionSheet(
                                  title: 'Job title / trade',
                                  options: _jobs,
                                  selected: _jobTitle,
                                  onSelected: (value) {
                                    setState(() {
                                      _jobTitle = value;
                                      _hasChanges = true;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _hasChanges ? _saveChanges : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.primaryText,
                            disabledBackgroundColor: AppColors.disabledButton,
                            disabledForegroundColor: AppColors.disabledText,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Save changes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 19,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Text(
            'My profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileCard({
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (trailing != null)
                trailing
              else if (icon != null)
                Icon(icon, color: AppColors.textPrimary, size: 21),
            ],
          ),
        ),
      ),
    );
  }
}
