import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum CertificateFilter { all, expiring, expired }

class CertificateItem {
  final String id;
  final String name;
  final DateTime? expiryDate;

  const CertificateItem({
    required this.id,
    required this.name,
    this.expiryDate,
  });
}

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({
    super.key,
    this.certificates = const [],
    this.onAddCertificate,
  });

  final List<CertificateItem> certificates;
  final VoidCallback? onAddCertificate;

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  final TextEditingController _searchController = TextEditingController();

  CertificateFilter _selectedFilter = CertificateFilter.all;
  bool _selectionMode = false;
  String _searchText = '';

  late List<CertificateItem> _certificates;

  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _certificates = List.of(widget.certificates);

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _expiredCount => _certificates.where(_isExpired).length;

  int get _expiringCount => _certificates.where(_isExpiring).length;

  bool _isExpired(CertificateItem item) {
    if (item.expiryDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return item.expiryDate!.isBefore(today);
  }

  bool _isExpiring(CertificateItem item) {
    if (item.expiryDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(const Duration(days: 30));

    return !item.expiryDate!.isBefore(today) &&
        !item.expiryDate!.isAfter(limit);
  }

  List<CertificateItem> get _filteredCertificates {
    return _certificates.where((certificate) {
      final matchesSearch =
          certificate.name.toLowerCase().contains(_searchText) ||
          certificate.id.toLowerCase().contains(_searchText);

      final matchesFilter = switch (_selectedFilter) {
        CertificateFilter.all => true,
        CertificateFilter.expiring => _isExpiring(certificate),
        CertificateFilter.expired => _isExpired(certificate),
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;

      if (!_selectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _deleteSelected() {
    setState(() {
      _certificates.removeWhere((item) => _selectedIds.contains(item.id));

      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: CustomAppBar(
        title: 'Certificates',
        // Use the CustomAppBar actions parameter.
        actions: [
          TextButton(
            onPressed: _toggleSelectionMode,
            child: Text(
              _selectionMode ? 'Cancel' : 'Select',
              style: const TextStyle(
                color: AppColors.certificatePrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            children: [
              _buildSearchField(),

              const SizedBox(height: 16),

              _buildFilters(),

              const SizedBox(height: 16),

              Expanded(
                child: _filteredCertificates.isEmpty
                    ? _buildEmptyState()
                    : _buildCertificateList(),
              ),

              const SizedBox(height: 12),

              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // SEARCH FIELD
  // ----------------------------------------------------

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.certificateSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.certificateBorder),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.certificateTextPrimary,
        ),
        cursorColor: AppColors.certificatePrimary,
        decoration: InputDecoration(
          hintText: 'Search certificates',
          hintStyle: const TextStyle(
            color: AppColors.certificateTextSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 23,
            color: AppColors.certificateIcon,
          ),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.certificateIcon,
                    size: 19,
                  ),
                  onPressed: _searchController.clear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // FILTER TABS
  // ----------------------------------------------------

  Widget _buildFilters() {
    return Row(
      children: [
        _filterButton(
          title: 'All ${_certificates.length}',
          filter: CertificateFilter.all,
        ),

        const SizedBox(width: 8),

        _filterButton(
          title: 'Expiring $_expiringCount',
          filter: CertificateFilter.expiring,
        ),

        const SizedBox(width: 8),

        _filterButton(
          title: 'Expired $_expiredCount',
          filter: CertificateFilter.expired,
        ),
      ],
    );
  }

  Widget _filterButton({
    required String title,
    required CertificateFilter filter,
  }) {
    final selected = _selectedFilter == filter;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 37,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.certificatePrimary
                : AppColors.certificateSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.certificatePrimary
                  : AppColors.certificateBorder,
            ),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppColors.certificateButtonText
                  : AppColors.certificateTextPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // EMPTY STATE
  // ----------------------------------------------------

  Widget _buildEmptyState() {
    final hasSearch = _searchText.isNotEmpty;

    final isTrulyEmpty = _certificates.isEmpty;

    final title = isTrulyEmpty
        ? 'No certificates yet'
        : hasSearch
        ? 'No matching certificates'
        : 'No certificates in this category';

    final subtitle = isTrulyEmpty
        ? 'Add a PDF or photo to start.'
        : hasSearch
        ? 'Try searching with a different name.'
        : 'Try another filter to see your certificates.';

    return Center(
      child: Transform.translate(
        offset: const Offset(0, -26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              color: AppColors.certificateIcon,
              size: 48,
            ),

            const SizedBox(height: 22),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.certificateTextPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.certificateTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // CERTIFICATE LIST
  // ----------------------------------------------------

  Widget _buildCertificateList() {
    final items = _filteredCertificates;

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedIds.contains(item.id);

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (_selectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedIds.remove(item.id);
                } else {
                  _selectedIds.add(item.id);
                }
              });
            } else {
              // TODO: Open certificate details.
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.certificateSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.certificateBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 28,
                  color: AppColors.certificateIcon,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.certificateTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${item.id}',
                        style: const TextStyle(
                          color: AppColors.certificateTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_selectionMode)
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected
                        ? AppColors.certificatePrimary
                        : AppColors.certificateIcon,
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.certificateIcon,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // BOTTOM BUTTON
  // ----------------------------------------------------

  Widget _buildBottomButton() {
    final isDeleting = _selectionMode && _selectedIds.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          context.push('/addCertifiate');
        },

        //  isDeleting
        //     ? _deleteSelected
        //     : _selectionMode
        //     ? null
        //     : widget.onAddCertificate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.certificatePrimary,
          foregroundColor: AppColors.certificateButtonText,
          disabledBackgroundColor: AppColors.certificatePrimary,
          disabledForegroundColor: AppColors.certificateButtonText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: Icon(
          isDeleting ? Icons.delete_outline_rounded : Icons.add_rounded,
          size: 22,
        ),
        label: Text(
          'Add certificate',
          // isDeleting
          //     ? 'Delete selected (${_selectedIds.length})'
          //     : _selectionMode
          //     ? 'Select certificates'
          //     : 'Add certificate',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
