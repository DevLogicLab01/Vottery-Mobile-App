import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import '../../services/unified_search_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import './widgets/search_results_widget.dart';
import './widgets/saved_searches_widget.dart';
import './widgets/trending_suggestions_widget.dart';
import './widgets/search_history_widget.dart';
import './widgets/filter_chips_widget.dart';

class UnifiedSearchSystemHub extends StatefulWidget {
  const UnifiedSearchSystemHub({super.key});

  @override
  State<UnifiedSearchSystemHub> createState() => _UnifiedSearchSystemHubState();
}

class _UnifiedSearchSystemHubState extends State<UnifiedSearchSystemHub>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  late TabController _tabController;
  bool _isLoading = false;
  bool _isSearching = false;
  String _selectedFilter = 'all'; // all, posts, users, groups, elections
  String _sortBy = 'relevance'; // relevance, recent, popular

  Map<String, dynamic> _searchResults = {};
  List<String> _savedSearches = [];
  List<Map<String, dynamic>> _trendingSuggestions = [];
  List<String> _searchHistory = [];

  final UnifiedSearchService _searchService = UnifiedSearchService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      setState(() {
        _savedSearches = [];
        _trendingSuggestions = [];
        _searchHistory = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _onSearchChanged() {
    // Debounce search input (300ms delay)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _searchResults = {};
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);

    try {
      final domains = _selectedFilter == 'all' ? null : [_selectedFilter];
      final grouped = await _searchService.searchAll(query);
      final flattened = <Map<String, dynamic>>[];
      grouped.forEach((domain, items) {
        for (final item in items) {
          flattened.add({...item, 'domain': domain});
        }
      });
      if (domains != null && domains.isNotEmpty) {
        flattened.removeWhere((item) => !domains.contains(item['domain']));
      }
      if (_sortBy == 'recent') {
        flattened.sort((a, b) {
          final ad = DateTime.tryParse(a['created_at']?.toString() ?? '');
          final bd = DateTime.tryParse(b['created_at']?.toString() ?? '');
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
      }
      final results = <String, dynamic>{
        'results': flattened.take(20).toList(),
        'query': query,
        'domains': domains,
        'sortBy': _sortBy,
      };

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  void _onSavedSearchTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _onTrendingSuggestionTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  Future<void> _saveCurrentSearch() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      if (!_savedSearches.contains(_searchController.text)) {
        _savedSearches.insert(0, _searchController.text);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search saved successfully')),
      );
    }
  }

  Future<void> _clearSearchHistory() async {
    setState(() => _searchHistory = []);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Search history cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'Unified Search',
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Unified Search',
          actions: [
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined),
                onPressed: _saveCurrentSearch,
                tooltip: 'Save Search',
              ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: EdgeInsets.all(2.w),
              color: Theme.of(context).cardColor,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search posts, users, groups, elections...',
                  hintStyle: TextStyle(fontSize: 14.sp),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = {};
                              _isSearching = false;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                ),
              ),
            ),

            // Filter Chips
            FilterChipsWidget(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() => _selectedFilter = filter);
                if (_searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              },
              selectedSort: _sortBy,
              onSortChanged: (sort) {
                setState(() => _sortBy = sort);
                if (_searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              },
            ),

            // Tab Bar
            if (_searchController.text.isNotEmpty)
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'All Results'),
                  Tab(text: 'Posts'),
                  Tab(text: 'Users'),
                  Tab(text: 'Groups'),
                  Tab(text: 'Elections'),
                ],
              ),

            // Content
            Expanded(
              child: _isLoading
                  ? const ShimmerSkeletonLoader(child: SizedBox())
                  : _searchController.text.isEmpty
                  ? _buildEmptySearchState()
                  : _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saved Searches
          if (_savedSearches.isNotEmpty) ...[
            SavedSearchesWidget(
              savedSearches: _savedSearches,
              onSearchTap: _onSavedSearchTap,
              onRemove: (query) async {
                setState(() => _savedSearches.remove(query));
              },
            ),
            SizedBox(height: 2.h),
          ],

          // Trending Suggestions
          if (_trendingSuggestions.isNotEmpty) ...[
            TrendingSuggestionsWidget(
              suggestions: _trendingSuggestions,
              onSuggestionTap: _onTrendingSuggestionTap,
            ),
            SizedBox(height: 2.h),
          ],

          // Search History
          if (_searchHistory.isNotEmpty)
            SearchHistoryWidget(
              history: _searchHistory,
              onHistoryTap: _onSavedSearchTap,
              onClearAll: _clearSearchHistory,
            ),

          // Empty state
          if (_savedSearches.isEmpty &&
              _trendingSuggestions.isEmpty &&
              _searchHistory.isEmpty)
            EnhancedEmptyStateWidget(
              title: 'Start Searching',
              description:
                  'Search across posts, users, groups, and elections with AI-powered semantic matching',
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty ||
        (_searchResults['results'] as List?)?.isEmpty == true) {
      return EnhancedEmptyStateWidget(
        title: 'No Results Found',
        description: 'Try different keywords or check trending suggestions',
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        SearchResultsWidget(results: _searchResults, domain: 'all'),
        SearchResultsWidget(results: _searchResults, domain: 'posts'),
        SearchResultsWidget(results: _searchResults, domain: 'users'),
        SearchResultsWidget(results: _searchResults, domain: 'groups'),
        SearchResultsWidget(results: _searchResults, domain: 'elections'),
      ],
    );
  }
}
