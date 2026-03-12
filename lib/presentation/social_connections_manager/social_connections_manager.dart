import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/follow_service.dart';
import '../../services/social_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/dual_header_bottom_bar.dart';
import '../../widgets/dual_header_top_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/connection_user_card_widget.dart';
import './widgets/friend_request_card_widget.dart';
import './widgets/suggested_connection_card_widget.dart';

/// Social Connections Manager - Comprehensive Friend/Unfriend and Follow/Unfollow system
/// Implements Facebook-style connection management with VP rewards
class SocialConnectionsManager extends StatefulWidget {
  const SocialConnectionsManager({super.key});

  @override
  State<SocialConnectionsManager> createState() =>
      _SocialConnectionsManagerState();
}

class _SocialConnectionsManagerState extends State<SocialConnectionsManager>
    with SingleTickerProviderStateMixin {
  final SocialService _socialService = SocialService.instance;
  final FollowService _followService = FollowService.instance;
  final VPService _vpService = VPService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _friendRequests = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  List<Map<String, dynamic>> _suggestedConnections = [];
  final Map<String, bool> _followingStatus = {};
  final Map<String, bool> _friendStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _socialService.getPendingRequests(),
        _socialService.getFriends(),
        _followService.getFollowers('current_user_id'),
        _followService.getFollowing('current_user_id'),
        _followService.getSuggestedUsers(),
      ]);

      setState(() {
        _friendRequests = results[0];
        _friends = results[1];
        _followers = results[2];
        _following = results[3];
        _suggestedConnections = results[4];
        _isLoading = false;
      });

      _loadConnectionStatuses();
    } catch (e) {
      debugPrint('Load connections error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadConnectionStatuses() async {
    for (var user in [
      ..._friends,
      ..._followers,
      ..._following,
      ..._suggestedConnections,
    ]) {
      final userId = user['id'] as String;
      _followingStatus[userId] = await _followService.isFollowing(userId);
      _friendStatus[userId] = await _socialService.isFriend(userId);
    }
    setState(() {});
  }

  Future<void> _handleFollowToggle(String userId) async {
    final isFollowing = _followingStatus[userId] ?? false;

    if (isFollowing) {
      final success = await _followService.unfollowUser(userId);
      if (success) {
        setState(() => _followingStatus[userId] = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unfollowed successfully')));
      }
    } else {
      final success = await _followService.followUser(userId);
      if (success) {
        setState(() => _followingStatus[userId] = true);
        await _vpService.awardSocialVP('follow_user', userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Following! +10 VP earned'),
            backgroundColor: AppTheme.accentLight,
          ),
        );
      }
    }
  }

  Future<void> _handleFriendRequest(String userId) async {
    final isFriend = _friendStatus[userId] ?? false;

    if (isFriend) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unfriend'),
          content: Text('Are you sure you want to remove this friend?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Unfriend', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final success = await _socialService.removeFriend(userId);
        if (success) {
          setState(() => _friendStatus[userId] = false);
          _loadData();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Friend removed')));
        }
      }
    } else {
      final success = await _socialService.sendFriendRequest(userId);
      if (success) {
        await _vpService.awardSocialVP('friend_request', userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent! +5 VP earned'),
            backgroundColor: AppTheme.accentLight,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'SocialConnectionsManager',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: DualHeaderTopBar(
          currentRoute: '/social-connections-manager',
          friendRequestsCount: _friendRequests.length,
        ),
        body: Column(
          children: [
            Container(
              color: AppTheme.surfaceLight,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryLight,
                unselectedLabelColor: AppTheme.textSecondaryLight,
                indicatorColor: AppTheme.vibrantYellow,
                indicatorWeight: 3,
                isScrollable: true,
                tabs: [
                  Tab(text: 'Requests (${_friendRequests.length})'),
                  Tab(text: 'Friends (${_friends.length})'),
                  Tab(text: 'Followers (${_followers.length})'),
                  Tab(text: 'Following (${_following.length})'),
                  Tab(text: 'Suggestions'),
                ],
              ),
            ),
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
                        _buildFriendRequests(),
                        _buildFriendsList(),
                        _buildFollowersList(),
                        _buildFollowingList(),
                        _buildSuggestedConnections(),
                      ],
                    ),
            ),
          ],
        ),
        bottomNavigationBar: DualHeaderBottomBar(
          currentRoute: '/social-connections-manager',
          onNavigate: (route) {
            Navigator.pushNamed(context, route);
          },
        ),
      ),
    );
  }

  Widget _buildFriendRequests() {
    if (_friendRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_disabled, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No pending friend requests',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: _friendRequests.length,
      itemBuilder: (context, index) {
        final request = _friendRequests[index];
        return FriendRequestCardWidget(
          request: request,
          onAccept: () async {
            await _socialService.acceptFriendRequest(request['id']);
            await _vpService.awardSocialVP(
              'accept_friend',
              request['requester_id'],
            );
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Friend request accepted! +15 VP earned'),
                backgroundColor: AppTheme.accentLight,
              ),
            );
          },
          onDecline: () async {
            await _socialService.rejectFriendRequest(request['id']);
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No friends yet',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Start connecting with people',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return ConnectionUserCardWidget(
          user: friend,
          actionType: 'unfriend',
          onAction: () => _handleFriendRequest(friend['id']),
        );
      },
    );
  }

  Widget _buildFollowersList() {
    if (_followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No followers yet',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: _followers.length,
      itemBuilder: (context, index) {
        final follower = _followers[index]['follower'] as Map<String, dynamic>;
        return ConnectionUserCardWidget(
          user: follower,
          actionType: _followingStatus[follower['id']] ?? false
              ? 'unfollow'
              : 'follow',
          onAction: () => _handleFollowToggle(follower['id']),
        );
      },
    );
  }

  Widget _buildFollowingList() {
    if (_following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'Not following anyone yet',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: _following.length,
      itemBuilder: (context, index) {
        final following =
            _following[index]['following'] as Map<String, dynamic>;
        return ConnectionUserCardWidget(
          user: following,
          actionType: 'unfollow',
          onAction: () => _handleFollowToggle(following['id']),
        );
      },
    );
  }

  Widget _buildSuggestedConnections() {
    if (_suggestedConnections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No suggestions available',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: _suggestedConnections.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestedConnections[index];
        return SuggestedConnectionCardWidget(
          user: suggestion,
          onAddFriend: () => _handleFriendRequest(suggestion['id']),
          onFollow: () => _handleFollowToggle(suggestion['id']),
        );
      },
    );
  }
}