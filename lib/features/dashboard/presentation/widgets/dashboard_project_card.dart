import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/features/dashboard/data/datasource/project_search_cache.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class DashboardProjectCard extends StatefulWidget {
  final String? selectedProject;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onRemoveProject;

  const DashboardProjectCard({
    super.key,
    this.selectedProject,
    this.onSearch,
    this.onRemoveProject,
  });

  @override
  State<DashboardProjectCard> createState() => _DashboardProjectCardState();
}

class _DashboardProjectCardState extends State<DashboardProjectCard> {
  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  final ProjectSearchCache _cache = ProjectSearchCache.instance;

  bool _isExpanded = false;

  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _recentSearches = _cache.getRecentSearches();
  }

  void _toggleExpanded() {
    if (widget.selectedProject != null) return;
    setState(() {
      _isExpanded = !_isExpanded;
      _loadHistory();
    });

    if (!_isExpanded) {
      _searchFocusNode.unfocus();
    }
  }

  // ==========================================
  // SEARCH PROJECT
  // ==========================================

  void _searchProject(String value) {
    final query = value.trim();

    if (query.isEmpty || widget.selectedProject != null) return;

    _cache.addSearch(query);

    setState(() {
      _loadHistory();
      _isExpanded = false;
      _searchController.clear();
    });

    _searchFocusNode.unfocus();

    // Future API / BLoC callback.
    widget.onSearch?.call(query);
  }

  // ==========================================
  // RECENT SEARCH CLICK
  // ==========================================

  void _onRecentSearchTap(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.collapsed(offset: query.length);

    _searchFocusNode.requestFocus();
  }

  // ==========================================
  // REMOVE SEARCH HISTORY
  // ==========================================

  void _removeSearch(String query) {
    _cache.removeSearch(query);

    setState(() {
      _loadHistory();
    });
  }

  void _clearHistory() {
    _cache.clearHistory();

    setState(() {
      _loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 591;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.65)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ====================================
          // PROJECT HEADER
          // ====================================
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.selectedProject == null ? _toggleExpanded : null,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: 108 * scale),

                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'SELECT PROJECT',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontSize: 28 * scale,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (widget.selectedProject != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: InputChip(
                label: Text(
                  widget.selectedProject!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onDeleted: widget.onRemoveProject,
                deleteIcon: const Icon(Icons.close_rounded),
                deleteButtonTooltipMessage: 'Remove project',
              ),
            ),

          // ====================================
          // EXPANDABLE CONTENT
          // ====================================
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        color: AppColors.cardBorder.withValues(alpha: 0.5),
                        height: 1,
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search field
                            _buildSearchField(),

                            const SizedBox(height: 22),

                            // Search history
                            _buildRecentSearches(),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SEARCH FIELD
  // ==========================================

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      textInputAction: TextInputAction.done,
      style: AppTextStyles.inputText,
      onSubmitted: _searchProject,
      decoration: InputDecoration(
        hintText: 'Search project...',
        hintStyle: AppTextStyles.inputHint,
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.iconSecondary,
        ),
        suffixIcon: IconButton(
          tooltip: 'Add project',
          onPressed: () {
            _searchProject(_searchController.text);
          },
          icon: const Icon(Icons.add_rounded, color: AppColors.white),
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.inputBorder.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.inputFocusedBorder,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // RECENT SEARCHES
  // ==========================================

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Text('No recent searches', style: AppTextStyles.bodySmall);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'RECENT SEARCHES',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ),
            TextButton(
              onPressed: _clearHistory,
              child: Text(
                'Clear All',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Column(
          children: List.generate(_recentSearches.length, (index) {
            final query = _recentSearches[index];

            return Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.history_rounded,
                  color: AppColors.iconSecondary,
                  size: 21,
                ),
                title: Text(
                  query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
                trailing: IconButton(
                  tooltip: 'Remove search',
                  onPressed: () => _removeSearch(query),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.iconSecondary,
                    size: 18,
                  ),
                ),
                onTap: () => _onRecentSearchTap(query),
              ),
            );
          }),
        ),
      ],
    );
  }
}
