import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:dropline/features/project_setup/presentation/pages/my_check_sheets_page.dart';
import 'package:dropline/features/project_setup/presentation/pages/setup_check_sheet_page.dart';
import 'package:flutter/material.dart';

// Add your project imports for:
// CustomAppBar
// AppColors
// AppTextStyles
// CheckSheetModel
// SetupCheckSheetPage

class SavedCheckSheetPage extends StatefulWidget {
  const SavedCheckSheetPage({
    super.key,
    required this.sheet,
    required this.companyName,
  });

  final CheckSheetModel sheet;
  final String companyName;

  @override
  State<SavedCheckSheetPage> createState() =>
      _SavedCheckSheetPageState();
}

class _SavedCheckSheetPageState
    extends State<SavedCheckSheetPage> {
  late CheckSheetModel currentSheet;
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    currentSheet = widget.sheet;
  }

  Future<void> openEditScreen() async {
    final updatedSheet =
        await Navigator.push<CheckSheetModel>(
      context,
      MaterialPageRoute(
        builder: (_) => SetupCheckSheetPage(
          sheet: currentSheet,
          companyName: widget.companyName,
          isEditing: true,
        ),
      ),
    );

    if (!mounted || updatedSheet == null) return;

    setState(() {
      currentSheet = updatedSheet;
      hasChanges = true;
    });
  }

  void goBack() {
    Navigator.pop(
      context,
      hasChanges ? currentSheet : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor(AppColors.background),

      appBar: CustomAppBar(
        title: '${currentSheet.code} · Saved',
        subtitle: widget.companyName,
        backgroundColor: context.backgroundColor(AppColors.background),
        onBackPressed: goBack,
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        children: [
          // Flow description
          // Text(
          //   currentSheet.description,
          //   style: AppTextStyles.custom(
          //     color: const Color(0xFFB8FF65),
          //     fontSize: 11,
          //     fontWeight: FontWeight.w600,
          //   ),
          // ),
          const SizedBox(height: 6),

          // Check sheet title
          Text(
            currentSheet.title,
            style: AppTextStyles.custom(
              color: context.foregroundColor(AppColors.textPrimary),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 20),

          if (currentSheet.points.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  'No checklist points available',
                  style: AppTextStyles.custom(
                    color: context.mutedColor(AppColors.textSecondary),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...List.generate(
              currentSheet.points.length,
              (index) => _buildCheckPoint(
                index: index,
                question: currentSheet.points[index],
              ),
            ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          color: context.backgroundColor(AppColors.background),
          border: Border(
            top: BorderSide(
              color: context.borderColor(AppColors.border),
              width: 0.7,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: openEditScreen,
              icon: const Icon(
                Icons.edit_outlined,
                size: 17,
              ),
              label: const Text('Edit check sheet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF092537),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckPoint({
    required int index,
    required String question,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      constraints: const BoxConstraints(
        minHeight: 49,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor(AppColors.surface),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: context.borderColor(AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1D4256),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderColor(AppColors.border)),
            ),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.custom(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              question,
              style: AppTextStyles.custom(
                color: context.foregroundColor(AppColors.textPrimary),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
