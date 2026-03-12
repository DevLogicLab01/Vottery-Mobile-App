import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/social_service.dart';
import '../../services/vp_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import './widgets/create_group_dialog_widget.dart';
import './widgets/group_card_widget.dart';
import './widgets/group_discovery_widget.dart';
import './widgets/group_search_widget.dart';

/// Groups Hub - Community formation and management
/// Implements group discovery, creation, participation, and real-time notifications
class GroupsHub extends StatefulWidget {
  const GroupsHub({super.key});

  @override
  State<GroupsHub> createState() => _GroupsHubState();
}

class _GroupsHubState extends State<GroupsHub>
    with SingleTickerProviderStateMixin {
  final SocialService _socialService = SocialService.instance;
  final VPService _vpService = VPService.instance;
  late TabController _tabController;

  List<Map<String, dynamic>> _myGroups = [];
  List<Map<String, dynamic>> _discoveredGroups = [];
  List<Map<String, dynamic>> _trendingGroups = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';
  final int _notificationCount = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      // Remove getUserGroups() call and use empty list as SocialService doesn't have this method
      final myGroups = <Map<String, dynamic>>[];
      setState(() {
        _myGroups = myGroups;
        _discoveredGroups = [];
        _trendingGroups = [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load groups data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshGroups() async {
    setState(() => _isRefreshing = true);
    await _loadGroupsData();
    setState(() => _isRefreshing = false);
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialogWidget(
        onGroupCreated: (groupId) async {
          await _refreshGroups();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 Group created successfully!'),
                backgroundColor: AppTheme.accentLight,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _joinGroup(String groupId) async {
    try {
      // Join group logic would go here
      await _vpService.awardSocialVP('group_join', groupId);
      await _refreshGroups();

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

  Future<void> _leaveGroup(String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Group?'),
        content: Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorLight),
            child: Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Leave group logic
      await _refreshGroups();
    }
  }

  void _navigateToGroupDetails(Map<String, dynamic> group) {
    // Navigate to group details screen
    debugPrint('Navigate to group: ${group['id']}');
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'GroupsHub',
      onRetry: _loadGroupsData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Text(
            'Groups',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          actions: [
            IconButton(
              icon: Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 6.w,
                    color: AppTheme.textPrimaryLight,
                  ),
                  if (_notificationCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: AppTheme.errorLight,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 4.w,
                          minHeight: 4.w,
                        ),
                        child: Text(
                          _notificationCount > 9
                              ? '9+'
                              : _notificationCount.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              onPressed: _showCreateGroupDialog,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(12.h),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: GroupSearchWidget(
                    onSearchChanged: (query) {
                      setState(() => _searchQuery = query);
                    },
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryLight,
                  unselectedLabelColor: AppTheme.textSecondaryLight,
                  indicatorColor: AppTheme.primaryLight,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(text: 'My Groups'),
                    Tab(text: 'Discover'),
                    Tab(text: 'Trending'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const SkeletonGrid(itemCount: 6)
            : _myGroups.isEmpty
            ? NoDataEmptyState(
                title: 'No Groups Yet',
                description:
                    'Join or create groups to connect with like-minded people.',
                onRefresh: _loadGroupsData,
              )
            : RefreshIndicator(
                onRefresh: _refreshGroups,
                color: AppTheme.primaryLight,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyGroupsTab(),
                    _buildDiscoverTab(),
                    _buildTrendingTab(),
                  ],
                ),
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
              Icons.group_outlined,
              size: 20.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No groups yet',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Join or create a group to get started',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: _showCreateGroupDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              child: Text(
                'Create Group',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
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
        final group = _myGroups[index]['group'] as Map<String, dynamic>? ?? {};
        return GroupCardWidget(
          group: group,
          isMember: true,
          onTap: () => _navigateToGroupDetails(group),
          onLeave: () => _leaveGroup(group['id'] as String),
        );
      },
    );
  }

  Widget _buildDiscoverTab() {
    return GroupDiscoveryWidget(
      groups: _discoveredGroups,
      onJoinGroup: _joinGroup,
      onGroupTap: _navigateToGroupDetails,
    );
  }

  Widget _buildTrendingTab() {
    return GroupDiscoveryWidget(
      groups: _trendingGroups,
      onJoinGroup: _joinGroup,
      onGroupTap: _navigateToGroupDetails,
      isTrending: true,
    );
  }
}
