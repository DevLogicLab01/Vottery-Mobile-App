import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/unified_search_service.dart';

class AdvancedUnifiedSearchScreen extends StatefulWidget {
  const AdvancedUnifiedSearchScreen({super.key});

  @override
  State<AdvancedUnifiedSearchScreen> createState() =>
      _AdvancedUnifiedSearchScreenState();
}

class _AdvancedUnifiedSearchScreenState
    extends State<AdvancedUnifiedSearchScreen>
    with SingleTickerProviderStateMixin {
  final UnifiedSearchService _searchService = UnifiedSearchService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  late TabController _tabController;
  bool _isLoading = false;
  bool _showSuggestions = false;
  final String _selectedCategory = 'All';

  Map<String, List<Map<String, dynamic>>> _searchResults = {};
  Map<String, List<Map<String, dynamic>>> _suggestions = {};
  List<String> _searchHistory = [];
  List<String> _trendingSearches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSearchHistory();
    _loadTrendingSearches();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isNotEmpty) {
        _getSuggestions(_searchController.text);
      } else {
        setState(() {
          _showSuggestions = false;
          _suggestions = {};
        });
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    final history = await _searchService.getSearchHistory();
    if (mounted) {
      setState(() => _searchHistory = history);
    }
  }

  Future<void> _loadTrendingSearches() async {
    final trending = await _searchService.getTrendingSearches();
    if (mounted) {
      setState(() => _trendingSearches = trending);
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.trim().isEmpty) return;

    final suggestions = await _searchService.getSearchSuggestions(query);
    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = true;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    try {
      await _searchService.saveSearchHistory(query);
      final results = await _searchService.searchAll(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search for posts, users, groups, elections...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = {};
                        _showSuggestions = false;
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
        bottom: _searchResults.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  Tab(text: 'All (${_getTotalResults()})'),
                  Tab(text: 'Users (${_searchResults['users']?.length ?? 0})'),
                  Tab(text: 'Posts (${_searchResults['posts']?.length ?? 0})'),
                  Tab(
                    text: 'Groups (${_searchResults['groups']?.length ?? 0})',
                  ),
                  Tab(
                    text:
                        'Elections (${_searchResults['elections']?.length ?? 0})',
                  ),
                ],
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_showSuggestions) {
      return _buildSuggestions();
    }

    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return _buildInitialState();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllResults(),
        _buildUserResults(),
        _buildPostResults(),
        _buildGroupResults(),
        _buildElectionResults(),
      ],
    );
  }

  Widget _buildInitialState() {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        if (_searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () async {
                  await _searchService.clearSearchHistory();
                  _loadSearchHistory();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ..._searchHistory
              .take(10)
              .map(
                (query) => ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(query),
                  trailing: IconButton(
                    icon: const Icon(Icons.north_west),
                    onPressed: () {
                      _searchController.text = query;
                      _performSearch(query);
                    },
                  ),
                  onTap: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                ),
              ),
          SizedBox(height: 2.h),
        ],
        if (_trendingSearches.isNotEmpty) ...[
          Text(
            'Trending Searches',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _trendingSearches
                .take(10)
                .map(
                  (query) => ActionChip(
                    avatar: const Icon(Icons.local_fire_department, size: 16),
                    label: Text(query),
                    onPressed: () {
                      _searchController.text = query;
                      _performSearch(query);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: EdgeInsets.all(2.w),
      children: [
        if (_suggestions['users']?.isNotEmpty ?? false) ...[
          _buildSuggestionSection(
            'Users',
            _suggestions['users']!,
            Icons.person,
          ),
          Divider(height: 2.h),
        ],
        if (_suggestions['posts']?.isNotEmpty ?? false) ...[
          _buildSuggestionSection(
            'Posts',
            _suggestions['posts']!,
            Icons.article,
          ),
          Divider(height: 2.h),
        ],
        if (_suggestions['groups']?.isNotEmpty ?? false) ...[
          _buildSuggestionSection(
            'Groups',
            _suggestions['groups']!,
            Icons.group,
          ),
          Divider(height: 2.h),
        ],
        if (_suggestions['elections']?.isNotEmpty ?? false) ...[
          _buildSuggestionSection(
            'Elections',
            _suggestions['elections']!,
            Icons.how_to_vote,
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionSection(
    String title,
    List<Map<String, dynamic>> items,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...items.map(
          (item) => ListTile(
            leading: Icon(icon, size: 20),
            title: Text(
              item['username'] ??
                  item['title'] ??
                  item['name'] ??
                  item['content']?.substring(0, 50) ??
                  '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.sp),
            ),
            onTap: () {
              _performSearch(_searchController.text);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'No results found for "${_searchController.text}"',
            style: TextStyle(fontSize: 16.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'Try different keywords or check spelling',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAllResults() {
    final allResults = <Map<String, dynamic>>[];
    _searchResults.forEach((category, items) {
      for (var item in items) {
        allResults.add({...item, '_category': category});
      }
    });

    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: allResults.length,
      itemBuilder: (context, index) {
        final item = allResults[index];
        final category = item['_category'];

        return _buildResultCard(item, category);
      },
    );
  }

  Widget _buildUserResults() {
    final users = _searchResults['users'] ?? [];
    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: users.length,
      itemBuilder: (context, index) => _buildResultCard(users[index], 'users'),
    );
  }

  Widget _buildPostResults() {
    final posts = _searchResults['posts'] ?? [];
    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: posts.length,
      itemBuilder: (context, index) => _buildResultCard(posts[index], 'posts'),
    );
  }

  Widget _buildGroupResults() {
    final groups = _searchResults['groups'] ?? [];
    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: groups.length,
      itemBuilder: (context, index) =>
          _buildResultCard(groups[index], 'groups'),
    );
  }

  Widget _buildElectionResults() {
    final elections = _searchResults['elections'] ?? [];
    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: elections.length,
      itemBuilder: (context, index) =>
          _buildResultCard(elections[index], 'elections'),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item, String category) {
    IconData icon;
    String title;
    String? subtitle;
    String? imageUrl;

    switch (category) {
      case 'users':
        icon = Icons.person;
        title = item['username'] ?? 'Unknown';
        subtitle = item['full_name'];
        imageUrl = item['avatar_url'];
        break;
      case 'posts':
        icon = Icons.article;
        title = item['content']?.substring(0, 50) ?? 'Post';
        subtitle = item['user_profiles']?['username'];
        imageUrl = item['media_url'];
        break;
      case 'groups':
        icon = Icons.group;
        title = item['name'] ?? 'Group';
        subtitle = '${item['member_count'] ?? 0} members';
        imageUrl = item['avatar_url'];
        break;
      case 'elections':
        icon = Icons.how_to_vote;
        title = item['title'] ?? 'Election';
        subtitle = item['description']?.substring(0, 50);
        imageUrl = item['media_url'];
        break;
      default:
        icon = Icons.search;
        title = 'Result';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: imageUrl != null
            ? CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 25)
            : CircleAvatar(radius: 25, child: Icon(icon)),
        title: Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 12.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Text(
            category.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        onTap: () => _navigateToDetail(item, category),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> item, String category) {
    // Navigate to appropriate detail screen based on category
    switch (category) {
      case 'users':
        Navigator.pushNamed(
          context,
          '/user-profile',
          arguments: item['id'],
        );
        break;
      case 'elections':
        Navigator.pushNamed(
          context,
          '/vote-casting',
          arguments: item['id'],
        );
        break;
      // Add other navigation cases as needed
    }
  }

  int _getTotalResults() {
    return _searchResults.values.fold(0, (sum, list) => sum + list.length);
  }
}