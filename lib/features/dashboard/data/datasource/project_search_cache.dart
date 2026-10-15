class ProjectSearchCache {
  ProjectSearchCache._();

  static final ProjectSearchCache instance =
      ProjectSearchCache._();

  final List<String> _recentSearches = [];

  static const int maxHistory = 10;

  List<String> getRecentSearches() {
    return List.unmodifiable(_recentSearches);
  }

  void addSearch(String query) {
    final search = query.trim();

    if (search.isEmpty) return;

    // Remove duplicate (case-insensitive).
    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == search.toLowerCase(),
    );

    // Latest first.
    _recentSearches.insert(0, search);

    // Keep only last 10 searches.
    if (_recentSearches.length > maxHistory) {
      _recentSearches.removeRange(
        maxHistory,
        _recentSearches.length,
      );
    }
  }

  void removeSearch(String query) {
    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == query.toLowerCase(),
    );
  }

  void clearHistory() {
    _recentSearches.clear();
  }
}