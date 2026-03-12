import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/history_card_widget.dart';
import './widgets/statistics_card_widget.dart';

class VoteHistory extends StatefulWidget {
  const VoteHistory({super.key});

  @override
  State<VoteHistory> createState() => _VoteHistoryState();
}

class _VoteHistoryState extends State<VoteHistory> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _allVotes = [];
  List<Map<String, dynamic>> _filteredVotes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;

  Map<String, dynamic> _activeFilters = {
    'dateRange': 'all',
    'voteType': 'all',
    'participationStatus': 'all',
    'outcome': 'all',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    _allVotes = _generateMockVotes();
    _filteredVotes = List.from(_allVotes);

    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreData() async {
    setState(() => _isLoadingMore = true);

    await Future.delayed(const Duration(milliseconds: 600));

    final moreVotes = _generateMockVotes(page: _currentPage + 1);

    if (moreVotes.isEmpty) {
      setState(() {
        _hasMoreData = false;
        _isLoadingMore = false;
      });
      return;
    }

    setState(() {
      _currentPage++;
      _allVotes.addAll(moreVotes);
      _applyFiltersAndSearch();
      _isLoadingMore = false;
    });
  }

  Future<void> _onRefresh() async {
    _currentPage = 1;
    _hasMoreData = true;
    await _loadInitialData();
  }

  List<Map<String, dynamic>> _generateMockVotes({int page = 1}) {
    if (page > 3) return [];

    final baseVotes = [
      {
        "id": "vote_${page}_1",
        "title": "Community Park Renovation Project",
        "description":
            "Vote on the proposed renovation plans for Central Community Park including new playground equipment and walking trails.",
        "date": DateTime.now().subtract(Duration(days: 2 + (page - 1) * 10)),
        "userSelection": "Option A: Modern Playground",
        "outcome": "won",
        "voteType": "community",
        "totalVotes": 1247,
        "userVotePercentage": 58.3,
        "isRecurring": false,
        "canVoteAgain": false,
      },
      {
        "id": "vote_${page}_2",
        "title": "Annual Budget Allocation 2026",
        "description":
            "Approve the proposed budget allocation for various city departments and infrastructure projects.",
        "date": DateTime.now().subtract(Duration(days: 5 + (page - 1) * 10)),
        "userSelection": "Approve Budget",
        "outcome": "won",
        "voteType": "government",
        "totalVotes": 3421,
        "userVotePercentage": 67.8,
        "isRecurring": true,
        "canVoteAgain": false,
      },
      {
        "id": "vote_${page}_3",
        "title": "New Traffic Light Installation",
        "description":
            "Decision on installing a new traffic light at the intersection of Main Street and Oak Avenue.",
        "date": DateTime.now().subtract(Duration(days: 8 + (page - 1) * 10)),
        "userSelection": "Against Installation",
        "outcome": "lost",
        "voteType": "infrastructure",
        "totalVotes": 892,
        "userVotePercentage": 42.1,
        "isRecurring": false,
        "canVoteAgain": false,
      },
      {
        "id": "vote_${page}_4",
        "title": "School Board Member Election",
        "description":
            "Vote for the new school board member to represent District 5.",
        "date": DateTime.now().subtract(Duration(days: 12 + (page - 1) * 10)),
        "userSelection": "Candidate: Sarah Johnson",
        "outcome": "tied",
        "voteType": "election",
        "totalVotes": 2156,
        "userVotePercentage": 50.0,
        "isRecurring": false,
        "canVoteAgain": false,
      },
      {
        "id": "vote_${page}_5",
        "title": "Library Hours Extension Proposal",
        "description":
            "Vote on extending public library hours to include Sunday operations.",
        "date": DateTime.now().subtract(Duration(days: 15 + (page - 1) * 10)),
        "userSelection": "Support Extension",
        "outcome": "won",
        "voteType": "community",
        "totalVotes": 1678,
        "userVotePercentage": 71.2,
        "isRecurring": false,
        "canVoteAgain": false,
      },
    ];

    return baseVotes;
  }

  void _applyFiltersAndSearch() {
    List<Map<String, dynamic>> filtered = List.from(_allVotes);

    if (_activeFilters['dateRange'] != 'all') {
      final now = DateTime.now();
      filtered = filtered.where((vote) {
        final voteDate = vote['date'] as DateTime;
        final difference = now.difference(voteDate).inDays;

        return _activeFilters['dateRange'] == 'week'
            ? difference <= 7
            : _activeFilters['dateRange'] == 'month'
            ? difference <= 30
            : _activeFilters['dateRange'] == 'year'
            ? difference <= 365
            : true;
      }).toList();
    }

    if (_activeFilters['voteType'] != 'all') {
      filtered = filtered
          .where((vote) => vote['voteType'] == _activeFilters['voteType'])
          .toList();
    }

    if (_activeFilters['outcome'] != 'all') {
      filtered = filtered
          .where((vote) => vote['outcome'] == _activeFilters['outcome'])
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (vote) =>
                (vote['title'] as String).toLowerCase().contains(searchTerm) ||
                (vote['description'] as String).toLowerCase().contains(
                  searchTerm,
                ),
          )
          .toList();
    }

    setState(() => _filteredVotes = filtered);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        activeFilters: _activeFilters,
        onApplyFilters: (filters) {
          setState(() {
            _activeFilters = filters;
            _applyFiltersAndSearch();
          });
        },
        onResetFilters: () {
          setState(() {
            _activeFilters = {
              'dateRange': 'all',
              'voteType': 'all',
              'participationStatus': 'all',
              'outcome': 'all',
            };
            _applyFiltersAndSearch();
          });
        },
      ),
    );
  }

  void _removeFromHistory(String voteId) {
    setState(() {
      _allVotes.removeWhere((vote) => vote['id'] == voteId);
      _applyFiltersAndSearch();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Vote removed from history'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            _loadInitialData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          color: theme.colorScheme.primary,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    children: [
                      Text(
                        'Vote History',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'filter_list',
                          color: theme.colorScheme.onPrimary,
                          size: 24,
                        ),
                        onPressed: _showFilterBottomSheet,
                        tooltip: 'Filter votes',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _applyFiltersAndSearch(),
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search votes...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      prefixIcon: CustomIconWidget(
                        iconName: 'search',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: CustomIconWidget(
                                iconName: 'clear',
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _applyFiltersAndSearch();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.5.h,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? _buildLoadingState(theme)
              : _filteredVotes.isEmpty
              ? EmptyStateWidget(
                  hasActiveFilters: _activeFilters.values.any(
                    (v) => v != 'all',
                  ),
                  hasSearchQuery: _searchController.text.isNotEmpty,
                  onClearFilters: () {
                    setState(() {
                      _searchController.clear();
                      _activeFilters = {
                        'dateRange': 'all',
                        'voteType': 'all',
                        'participationStatus': 'all',
                        'outcome': 'all',
                      };
                      _applyFiltersAndSearch();
                    });
                  },
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    itemCount:
                        _filteredVotes.length + 2 + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return StatisticsCardWidget(
                          totalVotes: _allVotes.length,
                          successRate: _calculateSuccessRate(),
                          currentStreak: _calculateStreak(),
                        );
                      }

                      if (index == _filteredVotes.length + 1) {
                        return _isLoadingMore
                            ? _buildLoadingMoreIndicator(theme)
                            : !_hasMoreData
                            ? _buildEndOfListIndicator(theme)
                            : const SizedBox.shrink();
                      }

                      if (index > _filteredVotes.length + 1) {
                        return const SizedBox.shrink();
                      }

                      final vote = _filteredVotes[index - 1];
                      return HistoryCardWidget(
                        vote: vote,
                        onViewResults: () {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamed('/vote-results');
                        },
                        onShare: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share functionality coming soon'),
                            ),
                          );
                        },
                        onRemove: () =>
                            _removeFromHistory(vote['id'] as String),
                        onVoteAgain: vote['canVoteAgain'] == true
                            ? () {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pushNamed('/vote-casting');
                              }
                            : null,
                        searchQuery: _searchController.text,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: 6,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSkeletonStatisticsCard(theme);
        }
        return _buildSkeletonCard(theme);
      },
    );
  }

  Widget _buildSkeletonStatisticsCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (index) {
              return Column(
                children: [
                  Container(
                    width: 15.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    width: 20.w,
                    height: 2.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70.w,
            height: 2.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            width: 40.w,
            height: 2.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            height: 2.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildEndOfListIndicator(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Center(
        child: Text(
          'No more votes to load',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  double _calculateSuccessRate() {
    if (_allVotes.isEmpty) return 0.0;
    final wonVotes = _allVotes.where((v) => v['outcome'] == 'won').length;
    return (wonVotes / _allVotes.length) * 100;
  }

  int _calculateStreak() {
    if (_allVotes.isEmpty) return 0;

    int streak = 0;
    for (var vote in _allVotes) {
      if (vote['outcome'] == 'won') {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
