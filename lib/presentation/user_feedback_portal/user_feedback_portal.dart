import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/feature_request_card_widget.dart';
import './widgets/feedback_submission_form_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/community_engagement_leaderboards_tab.dart';

class UserFeedbackPortal extends StatefulWidget {
  const UserFeedbackPortal({super.key});

  @override
  State<UserFeedbackPortal> createState() => _UserFeedbackPortalState();
}

class _UserFeedbackPortalState extends State<UserFeedbackPortal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _auth = AuthService.instance;
  final _client = SupabaseService.instance.client;

  List<Map<String, dynamic>> _featureRequests = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  final List<String> _categories = [
    'all',
    'elections',
    'analytics',
    'payments',
    'security',
    'ai',
    'communication',
    'gamification',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFeatureRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFeatureRequests() async {
    setState(() => _isLoading = true);

    try {
      var query = _client.from('feature_requests').select();

      if (_selectedCategory != 'all') {
        query = query.eq('category', _selectedCategory);
      }

      final response = await query.order('created_at', ascending: false);

      setState(() {
        _featureRequests = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load feature requests error: $e');
      setState(() {
        _featureRequests = _getMockData();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockData() {
    return [
      {
        'id': '1',
        'title': 'Dark Mode Support',
        'description': 'Add dark mode theme option for better viewing at night',
        'category': 'other',
        'status': 'under_review',
        'priority': 'medium',
        'vote_count': 144,
        'created_at': DateTime.now().subtract(const Duration(days: 5)),
        'user_id': 'user123',
      },
      {
        'id': '2',
        'title': 'Export Vote History',
        'description': 'Allow users to export their voting history as CSV/PDF',
        'category': 'elections',
        'status': 'in_progress',
        'priority': 'high',
        'vote_count': 84,
        'created_at': DateTime.now().subtract(const Duration(days: 10)),
        'user_id': 'user456',
      },
      {
        'id': '3',
        'title': 'Faster Vote Loading',
        'description': 'Improve vote loading speed on slow connections',
        'category': 'analytics',
        'status': 'submitted',
        'priority': 'critical',
        'vote_count': 226,
        'created_at': DateTime.now().subtract(const Duration(days: 2)),
        'user_id': 'user789',
      },
      {
        'id': '4',
        'title': 'Two-Factor Authentication',
        'description': 'Add 2FA for enhanced account security',
        'category': 'security',
        'status': 'implemented',
        'priority': 'high',
        'vote_count': 309,
        'created_at': DateTime.now().subtract(const Duration(days: 30)),
        'user_id': 'user101',
      },
    ];
  }

  Future<void> _voteOnFeature(String featureId, bool isUpvote) async {
    if (!_auth.isAuthenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in to vote')));
      return;
    }

    try {
      await _client.from('feature_votes').upsert({
        'feature_request_id': featureId,
        'user_id': _auth.currentUser!.id,
        'vote_type': isUpvote ? 'upvote' : 'downvote',
      });

      await _loadFeatureRequests();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vote recorded! You earned 5 VP'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Vote on feature error: $e');
    }
  }

  void _showSubmissionForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedbackSubmissionFormWidget(
        onSubmit: (title, description, category) {
          Navigator.of(context).pop();
          _submitFeatureRequest(title, description, category);
        },
      ),
    );
  }

  Future<void> _submitFeatureRequest(
    String title,
    String description,
    String category,
  ) async {
    if (!_auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to submit feedback')),
      );
      return;
    }

    try {
      await _client.from('feature_requests').insert({
        'title': title,
        'description': description,
        'category': category,
        'user_id': _auth.currentUser!.id,
        'status': 'submitted',
        'priority': 'medium',
      });

      await _loadFeatureRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'UserFeedbackPortal',
      onRetry: _loadFeatureRequests,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Feedback Portal',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'filter_list',
                color: theme.appBarTheme.foregroundColor!,
                size: 24,
              ),
              onPressed: () => _showCategoryFilter(),
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _featureRequests.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.feedback_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'No Feedback Submitted',
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Share your thoughts and help us improve the platform.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    ElevatedButton.icon(
                      onPressed: _loadFeatureRequests,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadFeatureRequests,
                child: Column(
                  children: [
                    _buildHeader(theme),
                    _buildTabBar(theme),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTrendingTab(theme),
                          _buildRecentTab(theme),
                          _buildImplementationTrackingTab(theme),
                          const CommunityEngagementLeaderboardsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showSubmissionForm,
          icon: CustomIconWidget(
            iconName: 'add',
            color: theme.floatingActionButtonTheme.foregroundColor!,
            size: 24,
          ),
          label: Text('Submit Feedback'),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: 'feedback',
              color: theme.colorScheme.onPrimary,
              size: 8.w,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Feedback',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_featureRequests.length} active requests',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Trending'),
          Tab(text: 'Recent'),
          Tab(text: 'Tracking'),
          Tab(text: 'Leaderboards'),
        ],
      ),
    );
  }

  Widget _buildTrendingTab(ThemeData theme) {
    final trendingRequests = List<Map<String, dynamic>>.from(_featureRequests)
      ..sort(
        (a, b) => ((b['vote_count'] ?? b['upvotes'] ?? 0) as int).compareTo(
          ((a['vote_count'] ?? a['upvotes'] ?? 0) as int),
        ),
      );

    return RefreshIndicator(
      onRefresh: _loadFeatureRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: trendingRequests.length,
        itemBuilder: (context, index) {
          return FeatureRequestCardWidget(
            request: trendingRequests[index],
            onVote: (isUpvote) =>
                _voteOnFeature(trendingRequests[index]['id'], isUpvote),
          );
        },
      ),
    );
  }

  Widget _buildRecentTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadFeatureRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _featureRequests.length,
        itemBuilder: (context, index) {
          return FeatureRequestCardWidget(
            request: _featureRequests[index],
            onVote: (isUpvote) =>
                _voteOnFeature(_featureRequests[index]['id'], isUpvote),
          );
        },
      ),
    );
  }

  Widget _buildImplementationTrackingTab(ThemeData theme) {
    final trackingItems = List<Map<String, dynamic>>.from(_featureRequests)
      ..sort((a, b) {
        final statusA = (a['status'] ?? '').toString();
        final statusB = (b['status'] ?? '').toString();
        return statusA.compareTo(statusB);
      });

    return RefreshIndicator(
      onRefresh: _loadFeatureRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: trackingItems.length,
        itemBuilder: (context, index) {
          return FeatureRequestCardWidget(
            request: trackingItems[index],
            onVote: (isUpvote) =>
                _voteOnFeature(trackingItems[index]['id'], isUpvote),
          );
        },
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Category',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            ..._categories.map((category) {
              return ListTile(
                title: Text(category),
                trailing: _selectedCategory == category
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedCategory = category);
                  Navigator.pop(context);
                  _loadFeatureRequests();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
