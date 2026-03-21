import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/voting_service.dart';
import '../../services/gemini_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../vote_dashboard/widgets/active_vote_card_widget.dart';
import '../vote_dashboard/widgets/empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';

class VoteDiscovery extends StatefulWidget {
  const VoteDiscovery({super.key});

  @override
  State<VoteDiscovery> createState() => _VoteDiscoveryState();
}

class _VoteDiscoveryState extends State<VoteDiscovery>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  List<Map<String, dynamic>> _allVotes = [];
  List<Map<String, dynamic>> _filteredVotes = [];
  List<Map<String, dynamic>> _aiRecommendations = [];
  bool _isLoading = false;
  bool _isLoadingRecommendations = false;
  String _selectedCategory = 'all';
  String _currentTab = 'trending';

  final List<String> _categories = [
    'all',
    'government',
    'community',
    'infrastructure',
    'education',
    'healthcare',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadVotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTab = [
          'trending',
          'recent',
          'popular',
          'ai_recommended',
        ][_tabController.index];
        if (_currentTab == 'ai_recommended' && _aiRecommendations.isEmpty) {
          _loadAIRecommendations();
        }
        _applyFilters();
      });
    }
  }

  Future<void> _loadVotes() async {
    setState(() => _isLoading = true);

    try {
      final elections = await VotingService.instance.getElections(limit: 100);

      final votesWithDetails = elections.map((election) {
        return {
          'id': election['id'],
          'title': election['title'] ?? 'Untitled Vote',
          'creator': election['created_by'] ?? 'Unknown',
          'creatorAvatar':
              'https://img.rocket.new/generatedImages/rocket_gen_img_12421743f-1764670653945.png',
          'creatorAvatarLabel': 'User avatar',
          'deadline': election['end_date'] != null
              ? DateTime.parse(election['end_date'])
              : DateTime.now().add(const Duration(days: 7)),
          'totalVotes': election['total_votes'] ?? 0,
          'participated': false,
          'status': _getVoteStatus(election),
          'progress': (election['total_votes'] ?? 0) / 1000.0,
          'description': election['description'] ?? '',
          'category': election['category'] ?? 'community',
          'trending_score': election['total_votes'] ?? 0,
        };
      }).toList();

      setState(() {
        _allVotes = votesWithDetails;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Load votes error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAIRecommendations() async {
    setState(() => _isLoadingRecommendations = true);

    try {
      final recommendations = await GeminiService.instance
          .getPersonalizedRecommendations(allVotes: _allVotes, limit: 10);

      setState(() {
        _aiRecommendations = recommendations;
      });
    } catch (e) {
      debugPrint('Load AI recommendations error: $e');
    } finally {
      setState(() => _isLoadingRecommendations = false);
    }
  }

  String _getVoteStatus(Map<String, dynamic> election) {
    if (election['status'] == 'closed') return 'participated';

    final endDate = election['end_date'] != null
        ? DateTime.parse(election['end_date'])
        : DateTime.now().add(const Duration(days: 7));
    final hoursRemaining = endDate.difference(DateTime.now()).inHours;

    if (hoursRemaining < 6) return 'urgent';
    if (hoursRemaining < 24) return 'ending_soon';
    return 'active';
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allVotes);

    if (_selectedCategory != 'all') {
      filtered = filtered
          .where((vote) => vote['category'] == _selectedCategory)
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((vote) {
        return (vote['title'] as String).toLowerCase().contains(searchTerm) ||
            (vote['description'] as String).toLowerCase().contains(searchTerm);
      }).toList();
    }

    switch (_currentTab) {
      case 'trending':
        filtered.sort(
          (a, b) => (b['trending_score'] as int).compareTo(
            a['trending_score'] as int,
          ),
        );
        break;
      case 'recent':
        filtered.sort(
          (a, b) =>
              (b['deadline'] as DateTime).compareTo(a['deadline'] as DateTime),
        );
        break;
      case 'popular':
        filtered.sort(
          (a, b) => (b['totalVotes'] as int).compareTo(a['totalVotes'] as int),
        );
        break;
      case 'ai_recommended':
        filtered = _aiRecommendations;
        break;
    }

    setState(() => _filteredVotes = filtered);
  }

  Future<void> _onRefresh() async {
    await _loadVotes();
    if (_currentTab == 'ai_recommended') {
      await _loadAIRecommendations();
    }
  }

  void _handleVoteNow(Map<String, dynamic> vote) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.voteCasting, arguments: vote['id']);
  }

  void _handleBookmark(Map<String, dynamic> vote) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vote bookmarked: ${vote["title"]}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleShare(Map<String, dynamic> vote) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${vote["title"]}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleDetails(Map<String, dynamic> vote) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.voteResults, arguments: vote['id']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'VoteDiscovery',
      onRetry: _loadVotes,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: 'Discover Votes'),
        body: Column(
          children: [
            Container(
              color: theme.cardColor,
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Search votes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    height: 5.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;

                        return Padding(
                          padding: EdgeInsets.only(right: 2.w),
                          child: FilterChip(
                            label: Text(
                              category == 'all'
                                  ? 'All'
                                  : category[0].toUpperCase() +
                                        category.substring(1),
                              style: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                                _applyFilters();
                              });
                            },
                            backgroundColor: theme.scaffoldBackgroundColor,
                            selectedColor: theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: theme.cardColor,
              child: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(text: 'Trending'),
                  Tab(text: 'Recent'),
                  Tab(text: 'Popular'),
                  Tab(icon: Icon(Icons.auto_awesome), text: 'AI Picks'),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : _currentTab == 'ai_recommended' &&
                          _isLoadingRecommendations
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Personalizing recommendations...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredVotes.isEmpty
                    ? EmptyStateWidget(onBrowseAll: () => _onRefresh())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(4.w),
                        itemCount: _filteredVotes.length,
                        itemBuilder: (context, index) {
                          final vote = _filteredVotes[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 3.w),
                            child: ActiveVoteCardWidget(
                              vote: vote,
                              onVoteNow: () => _handleVoteNow(vote),
                              onBookmark: () => _handleBookmark(vote),
                              onShare: () => _handleShare(vote),
                              onDetails: () => _handleDetails(vote),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
