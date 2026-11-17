import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:dropline/features/project_setup/presentation/pages/SavedCheckSheetPage.dart';
import 'package:dropline/features/project_setup/presentation/pages/setup_check_sheet_page.dart';
import 'package:flutter/material.dart';

class MyCheckSheetsPage extends StatelessWidget {
  const MyCheckSheetsPage({
    super.key,
    required this.projectName,
    required this.companyName,
  });

  final String projectName;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final List<CheckSheetModel> checkSheets = [
      CheckSheetModel(
        code: 'CS-01',
        title: 'Plastering area check',
        description: 'Apartment finishes · PL-01 · Taking over',
        isSaved: true,
      ),
      CheckSheetModel(
        code: 'CS-02',
        title: 'Plaster finish check',
        description: 'Apartment finishes · PL-01 · Handing on',
        isSaved: true,
      ),
      CheckSheetModel(
        code: 'CS-05',
        title: 'Touch-ups',
        description: 'Apartment finishes · PL-02 · Taking over',
        isSaved: false,
      ),
      CheckSheetModel(
        code: 'CS-06',
        title: 'Repairs complete check',
        description: 'Apartment finishes · PL-02 · Handing on',
        isSaved: true,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'My check sheets',
        subtitle: '$projectName · $companyName',
        backgroundColor: AppColors.background,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header

            // Container(
            //   padding: const EdgeInsets.fromLTRB(17, 12, 16, 14),
            //   decoration: const BoxDecoration(
            //     border: Border(
            //       bottom: BorderSide(color: AppColors.border, width: 0.7),
            //     ),
            //   ),
            //   child: Row(
            //     children: [
            //       InkWell(
            //         onTap: () => Navigator.pop(context),
            //         borderRadius: BorderRadius.circular(11),
            //         child: Container(
            //           width: 44,
            //           height: 44,
            //           decoration: BoxDecoration(
            //             color: AppColors.surface,
            //             borderRadius: BorderRadius.circular(11),
            //             border: Border.all(color: AppColors.border),
            //           ),
            //           child: const Icon(
            //             Icons.chevron_left,
            //             color: AppColors.iconSecondary,
            //             size: 23,
            //           ),
            //         ),
            //       ),

            //       const SizedBox(width: 9),

            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'My check sheets',
            //               style: AppTextStyles.custom(
            //                 color: AppColors.textPrimary,
            //                 fontSize: 24,
            //                 fontWeight: FontWeight.w800,
            //                 height: 1.1,
            //               ),
            //             ),
            //             const SizedBox(height: 3),
            //             Text(
            //               '$projectName · $companyName',
            //               maxLines: 1,
            //               overflow: TextOverflow.ellipsis,
            //               style: AppTextStyles.custom(
            //                 color: AppColors.textSecondary,
            //                 fontSize: 11,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // Checklist content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(17, 15, 13, 20),
                children: [
                  Text(
                    'Your flows assign these sheets to your company.',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ...checkSheets.map(
                    (sheet) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _buildCheckSheetCard(context, sheet),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckSheetCard(BuildContext context, CheckSheetModel sheet) {
    return InkWell(
     onTap: () {
  if (sheet.isSaved) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedCheckSheetPage(
          sheet: sheet,
          companyName: companyName,
        ),
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetupCheckSheetPage(
          sheet: sheet,
          companyName: companyName,
        ),
      ),
    );
  }
},
      borderRadius: BorderRadius.circular(11),
      child: Container(
        // constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 17),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // Code badge
            Container(
              width: 49,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                sheet.code,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),

            const SizedBox(width: 9),

            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sheet.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    sheet.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 7),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: sheet.isSaved
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: sheet.isSaved ? AppColors.success : AppColors.warning,
                  width: 0.8,
                ),
              ),
              child: Text(
                sheet.isSaved ? 'Saved' : 'Set up',
                style: AppTextStyles.labelSmall.copyWith(
                  color: sheet.isSaved ? AppColors.success : AppColors.warning,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Check sheet model
class CheckSheetModel {
  final String code;
  final String title;
  final String description;
  final bool isSaved;
  final List<String> points;

  const CheckSheetModel({
    required this.code,
    required this.title,
    required this.description,
    required this.isSaved,
    this.points = const [],
  });
}
