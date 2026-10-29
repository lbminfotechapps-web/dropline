import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'add_compnies.dart';

class FindCompanyScreen extends StatefulWidget {
  const FindCompanyScreen({
    super.key,
    this.projectName = 'Laxmi Gauri',
    this.onCreateCompany,
    this.onCompanySelected,
  });

  final String projectName;
  final VoidCallback? onCreateCompany;
  final ValueChanged<CompanyItem>? onCompanySelected;

  @override
  State<FindCompanyScreen> createState() => _FindCompanyScreenState();
}

class CompanyItem {
  final String id;
  final String name;

  const CompanyItem({required this.id, required this.name});
}

class _FindCompanyScreenState extends State<FindCompanyScreen> {
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = '';

  // Replace this with your API response.
  final List<CompanyItem> companies = [];

  List<CompanyItem> get filteredCompanies {
    if (searchQuery.trim().isEmpty) {
      return companies;
    }

    return companies.where((company) {
      return company.name.toLowerCase().contains(
            searchQuery.trim().toLowerCase(),
          ) ||
          company.id.toLowerCase().contains(searchQuery.trim().toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(title: 'Find company', subtitle: widget.projectName),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                'Already on Dropline? Use the existing company ID.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildSearchField(),

            const SizedBox(height: 12),

            Expanded(child: _buildCompanyContent()),

            const SizedBox(height: 12),

            _buildCreateCompanyButton(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // HEADER
  // ---------------------------------------------------

  // Widget _buildHeader() {
  //   return Row(
  //     children: [
  //       InkWell(
  //         onTap: () => Navigator.maybePop(context),
  //         borderRadius: BorderRadius.circular(10),
  //         child: Container(
  //           height: 40,
  //           width: 40,
  //           decoration: BoxDecoration(
  //             color: AppColors.surface,
  //             borderRadius: BorderRadius.circular(10),
  //             border: Border.all(color: AppColors.border),
  //           ),
  //           child: const Icon(
  //             Icons.arrow_back_ios_new_rounded,
  //             color: AppColors.iconColor,
  //             size: 16,
  //           ),
  //         ),
  //       ),

  //       const SizedBox(width: 10),

  //       Expanded(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             const Text(
  //               'Find company',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.w700,
  //                 color: AppColors.textPrimary,
  //               ),
  //             ),

  //             const SizedBox(height: 3),

  //             Text(
  //               widget.projectName,
  //               style: const TextStyle(
  //                 fontSize: 11,
  //                 color: AppColors.textSecondary,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // ---------------------------------------------------
  // SEARCH
  // ---------------------------------------------------

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: 'Search company name or ID',
          hintStyle: const TextStyle(color: AppColors.hintText, fontSize: 12),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.iconColor,
            size: 23,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(
                    Icons.cancel_rounded,
                    color: AppColors.hintText,
                    size: 17,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // COMPANY CONTENT
  // ---------------------------------------------------

  Widget _buildCompanyContent() {
    final results = filteredCompanies;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: results.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _buildCompanyCard(results[index]);
              },
            ),
    );
  }

  // ---------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.iconColor,
              size: 47,
            ),

            const SizedBox(height: 14),

            const Text(
              'No matching company found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Check the spelling or create a new company.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // COMPANY RESULT
  // ---------------------------------------------------

  Widget _buildCompanyCard(CompanyItem company) {
    return InkWell(
      onTap: () {
        widget.onCompanySelected?.call(company);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business_outlined,
                color: AppColors.iconColor,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Company ID: ${company.id}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: AppColors.iconColor),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // CREATE BUTTON
  // ---------------------------------------------------

  Widget _buildCreateCompanyButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton.icon(
        onPressed: widget.onCreateCompany ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddCompaniesPage(),
                ),
              );
            },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Create new company',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
