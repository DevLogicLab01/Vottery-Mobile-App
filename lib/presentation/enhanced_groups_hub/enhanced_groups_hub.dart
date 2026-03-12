import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/social_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/dual_header_bottom_bar.dart';
import '../../widgets/dual_header_top_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/group_analytics_widget.dart';
import './widgets/group_discovery_algorithm_widget.dart';
import './widgets/group_event_calendar_widget.dart';
import './widgets/member_moderation_dashboard_widget.dart';

/// Enhanced Groups Hub - Advanced group discovery and management
/// Implements intelligent algorithms, comprehensive moderation tools, and Facebook-style group system
class EnhancedGroupsHub extends StatefulWidget {
  const EnhancedGroupsHub({super.key});

  @override
  State<EnhancedGroupsHub> createState() => _EnhancedGroupsHubState();
}

class _EnhancedGroupsHubState extends State<EnhancedGroupsHub>
    with SingleTickerProviderStateMixin {
  final SocialService _socialService = SocialService.instance;
  final VPService _vpService = VPService.instance;
  late TabController _tabController;

  List<Map<String, dynamic>> _myGroups = [];
  List<Map<String, dynamic>> _discoveredGroups = [];
  List<Map<String, dynamic>> _trendingGroups = [];
  List<Map<String, dynamic>> _recommendedGroups = [];
  bool _isLoading = true;
  final bool _isAdmin = false;
  String? _selectedGroupId;
  String _filterCategory = 'All';
  String _sortBy = 'activity';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadGroupsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupsData() async {
    setState(() => _isLoading = true);

    try {
      // Simulate AI-powered group discovery algorithm
      final myGroups = <Map<String, dynamic>>[];
      final discovered = _generateDiscoveredGroups();
      final trending = _generateTrendingGroups();
      final recommended = _generateRecommendedGroups();

      setState(() {
        _myGroups = myGroups;
        _discoveredGroups = discovered;
        _trendingGroups = trending;
        _recommendedGroups = recommended;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load groups data error: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _generateDiscoveredGroups() {
    return [
      {
        'id': 'group_1',
        'name': 'Civic Engagement Alliance',
        'description': 'Join thousands discussing local governance and policy',
        'member_count': 12450,
        'activity_level': 'high',
        'engagement_rate': 0.85,
        'join_probability': 0.92,
        'is_public': true,
        'category': 'Politics',
        'cover_image_url':
            'https://images.unsplash.com/photo-1507759869341-3e38e6d2fd4f',
        'post_frequency': 'Daily',
        'moderation_quality': 'Excellent',
      },
      {
        'id': 'group_2',
        'name': 'Community Voting Hub',
        'description': 'Grassroots movements and local election discussions',
        'member_count': 8320,
        'activity_level': 'medium',
        'engagement_rate': 0.72,
        'join_probability': 0.78,
        'is_public': true,
        'category': 'Community',
        'cover_image_url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1f3f6ed35-1765155383457.png',
        'post_frequency': 'Multiple times per week',
        'moderation_quality': 'Good',
      },
      {
        'id': 'group_3',
        'name': 'Democracy Advocates Network',
        'description': 'Promoting transparency and voter education worldwide',
        'member_count': 15680,
        'activity_level': 'high',
        'engagement_rate': 0.88,
        'join_probability': 0.85,
        'is_public': false,
        'category': 'Advocacy',
        'cover_image_url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1816c9abe-1768473660756.png',
        'post_frequency': 'Daily',
        'moderation_quality': 'Excellent',
      },
    ];
  }

  List<Map<String, dynamic>> _generateTrendingGroups() {
    return [
      {
        'id': 'trend_1',
        'name': 'Election 2026 Watch',
        'description': 'Real-time updates and analysis of upcoming elections',
        'member_count': 24500,
        'growth_rate': '+2.5K this week',
        'trending_score': 98,
        'is_public': true,
        'category': 'Politics',
        'cover_image_url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1997c6632-1765121614009.png',
      },
      {
        'id': 'trend_2',
        'name': 'Youth Voters Coalition',
        'description': 'Empowering young voices in democratic processes',
        'member_count': 18200,
        'growth_rate': '+1.8K this week',
        'trending_score': 94,
        'is_public': true,
        'category': 'Youth',
        'cover_image_url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1974ce7b9-1770681603620.png',
      },
    ];
  }

  List<Map<String, dynamic>> _generateRecommendedGroups() {
    return [
      {
        'id': 'rec_1',
        'name': 'Local Policy Makers Forum',
        'description': 'Based on your voting patterns and interests',
        'member_count': 5420,
        'match_score': 95,
        'reason': 'Matches your interest in local governance',
        'mutual_members': 12,
        'is_public': true,
        'category': 'Local',
        'cover_image_url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1788b64f7-1769066400289.png',
      },
    ];
  }

  Future<void> _joinGroup(String groupId) async {
    try {
      await _vpService.awardSocialVP('group_join', groupId);
      await _loadGroupsData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Joined group! +5 VP earned'),
            backgroundColor: AppTheme.accentLight,
          ),
        );
      }
    } catch (e) {
      debugPrint('Join group error: $e');
    }
  }

  void _applyFilters(String category, String sortBy) {
    setState(() {
      _filterCategory = category;
      _sortBy = sortBy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'EnhancedGroupsHub',
      onRetry: _loadGroupsData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: DualHeaderTopBar(
          currentRoute: '/groups-hub',
          friendRequestsCount: 0,
        ),
        body: Column(
          children: [
            // Enhanced Search and Filter Bar
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search groups by name, topic, or interest...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.primaryLight,
                      ),
                      suffixIcon: Icon(
                        Icons.tune,
                        color: AppTheme.primaryLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: AppTheme.borderLight),
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', Icons.grid_view),
                        _buildFilterChip('Politics', Icons.account_balance),
                        _buildFilterChip('Community', Icons.people),
                        _buildFilterChip('Advocacy', Icons.campaign),
                        _buildFilterChip('Local', Icons.location_city),
                        _buildFilterChip('Youth', Icons.school),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.vibrantYellow,
                unselectedLabelColor: AppTheme.textSecondaryLight,
                indicatorColor: AppTheme.vibrantYellow,
                indicatorWeight: 3,
                isScrollable: true,
                labelStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'Discovery'),
                  Tab(text: 'My Groups'),
                  Tab(text: 'Trending'),
                  Tab(text: 'Moderation'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'Events'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryLight,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        GroupDiscoveryAlgorithmWidget(
                          discoveredGroups: _discoveredGroups,
                          recommendedGroups: _recommendedGroups,
                          onJoinGroup: _joinGroup,
                        ),
                        _buildMyGroupsTab(),
                        _buildTrendingTab(),
                        MemberModerationDashboardWidget(
                          groupId: _selectedGroupId ?? '',
                          isAdmin: _isAdmin,
                        ),
                        GroupAnalyticsWidget(groupId: _selectedGroupId ?? ''),
                        GroupEventCalendarWidget(
                          groupId: _selectedGroupId ?? '',
                        ),
                      ],
                    ),
            ),
          ],
        ),
        bottomNavigationBar: DualHeaderBottomBar(
          currentRoute: '/groups-hub',
          onNavigate: (route) {
            Navigator.pushNamed(context, route);
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _filterCategory == label;
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 4.w,
              color: isSelected ? Colors.white : AppTheme.primaryLight,
            ),
            SizedBox(width: 1.w),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterCategory = label);
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryLight,
        labelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppTheme.primaryLight,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryLight : AppTheme.borderLight,
        ),
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    if (_myGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 20.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No groups yet',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Join groups to connect with communities',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: _myGroups.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final group = _myGroups[index];
        return _buildGroupCard(group, isMember: true);
      },
    );
  }

  Widget _buildTrendingTab() {
    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: _trendingGroups.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final group = _trendingGroups[index];
        return _buildTrendingGroupCard(group);
      },
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, {bool isMember = false}) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedGroupId = group['id']);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
              child: CustomImageWidget(
                imageUrl: group['cover_image_url'],
                height: 20.h,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: 'Group cover image for ${group['name']}',
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group['name'],
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (group['is_public'] != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: group['is_public']
                                ? AppTheme.accentLight.withAlpha(51)
                                : AppTheme.warningLight.withAlpha(51),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            group['is_public'] ? 'Public' : 'Private',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: group['is_public']
                                  ? AppTheme.accentLight
                                  : AppTheme.warningLight,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    group['description'],
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.5.h),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 4.w,
                        color: AppTheme.textSecondaryLight,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${group['member_count']} members',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      Spacer(),
                      if (!isMember)
                        ElevatedButton(
                          onPressed: () => _joinGroup(group['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryLight,
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 0.8.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: Text(
                            'Join',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingGroupCard(Map<String, dynamic> group) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.vibrantYellow, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vibrantYellow.withAlpha(51),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                child: CustomImageWidget(
                  imageUrl: group['cover_image_url'],
                  height: 20.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel: 'Trending group cover for ${group['name']}',
                ),
              ),
              Positioned(
                top: 2.h,
                right: 4.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.vibrantYellow,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 4.w, color: Colors.white),
                      SizedBox(width: 1.w),
                      Text(
                        'Trending',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['name'],
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  group['description'],
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 4.w,
                      color: AppTheme.textSecondaryLight,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${group['member_count']} members',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Icon(
                      Icons.arrow_upward,
                      size: 4.w,
                      color: AppTheme.accentLight,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      group['growth_rate'],
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.accentLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}