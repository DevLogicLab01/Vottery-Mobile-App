import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/follow_service.dart';
import '../../services/social_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/dual_header_bottom_bar.dart';
import '../../widgets/dual_header_top_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/bulk_action_bar_widget.dart';
import './widgets/incoming_request_card_widget.dart';
import './widgets/mutual_friends_widget.dart';
import './widgets/outgoing_request_card_widget.dart';
import './widgets/suggested_friend_card_widget.dart';

/// Friend Requests Hub - Comprehensive social connection management
/// Implements Facebook-style friend request handling with bulk actions and intelligent suggestions
class FriendRequestsHub extends StatefulWidget {
  const FriendRequestsHub({super.key});

  @override
  State<FriendRequestsHub> createState() => _FriendRequestsHubState();
}

class _FriendRequestsHubState extends State<FriendRequestsHub>
    with SingleTickerProviderStateMixin {
  final SocialService _socialService = SocialService.instance;
  final FollowService _followService = FollowService.instance;
  final VPService _vpService = VPService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  bool _isBulkMode = false;
  final Set<String> _selectedRequests = {};

  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];
  List<Map<String, dynamic>> _suggestedFriends = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        _socialService.getSentRequests(),
        _followService.getSuggestedUsers(),
      ]);

      setState(() {
        _incomingRequests = results[0];
        _outgoingRequests = results[1];
        _suggestedFriends = _generateSuggestedFriends();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load friend requests error: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _generateSuggestedFriends() {
    return [
      {
        'id': 'user_1',
        'full_name': 'Sarah Johnson',
        'username': 'sarahjohnson',
        'avatar_url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_14c3ba85a-1767889524234.png',
        'mutual_friends': 12,
        'shared_groups': 3,
        'match_score': 95,
        'reason': 'Active in Civic Engagement Alliance',
        'location': 'New York, NY',
      },
      {
        'id': 'user_2',
        'full_name': 'Michael Chen',
        'username': 'michaelchen',
        'avatar_url':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
        'mutual_friends': 8,
        'shared_groups': 2,
        'match_score': 88,
        'reason': 'Similar voting patterns',
        'location': 'San Francisco, CA',
      },
      {
        'id': 'user_3',
        'full_name': 'Emily Rodriguez',
        'username': 'emilyrodriguez',
        'avatar_url':
            'https://images.unsplash.com/photo-1731419223586-902ceab212d5',
        'mutual_friends': 15,
        'shared_groups': 4,
        'match_score': 92,
        'reason': 'Member of Community Voting Hub',
        'location': 'Austin, TX',
      },
    ];
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      final success = await _socialService.acceptFriendRequest(requestId);
      if (success) {
        await _vpService.awardSocialVP('accept_friend', requestId);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Friend request accepted! +10 VP earned'),
              backgroundColor: AppTheme.accentLight,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Accept request error: $e');
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      final success = await _socialService.rejectFriendRequest(requestId);
      if (success) {
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request declined'),
              backgroundColor: AppTheme.textSecondaryLight,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Decline request error: $e');
    }
  }

  Future<void> _ignoreRequest(String requestId) async {
    try {
      await _socialService.rejectFriendRequest(requestId);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ignored'),
            backgroundColor: AppTheme.textSecondaryLight,
          ),
        );
      }
    } catch (e) {
      debugPrint('Ignore request error: $e');
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await _socialService.rejectFriendRequest(requestId);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request cancelled'),
            backgroundColor: AppTheme.textSecondaryLight,
          ),
        );
      }
    } catch (e) {
      debugPrint('Cancel request error: $e');
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    try {
      final success = await _socialService.sendFriendRequest(userId);
      if (success) {
        await _vpService.awardSocialVP('friend_request', userId);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Friend request sent! +5 VP earned'),
              backgroundColor: AppTheme.accentLight,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Send friend request error: $e');
    }
  }

  void _toggleBulkMode() {
    setState(() {
      _isBulkMode = !_isBulkMode;
      if (!_isBulkMode) {
        _selectedRequests.clear();
      }
    });
  }

  void _toggleSelection(String requestId) {
    setState(() {
      if (_selectedRequests.contains(requestId)) {
        _selectedRequests.remove(requestId);
      } else {
        _selectedRequests.add(requestId);
      }
    });
  }

  Future<void> _acceptAllSelected() async {
    for (final requestId in _selectedRequests) {
      await _acceptRequest(requestId);
    }
    setState(() {
      _selectedRequests.clear();
      _isBulkMode = false;
    });
  }

  Future<void> _declineAllSelected() async {
    for (final requestId in _selectedRequests) {
      await _declineRequest(requestId);
    }
    setState(() {
      _selectedRequests.clear();
      _isBulkMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'FriendRequestsHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: DualHeaderTopBar(
          currentRoute: AppRoutes.friendRequestsHub,
          friendRequestsCount: _incomingRequests.length,
        ),
        body: Column(
          children: [
            // Header with Bulk Actions
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  Text(
                    'Friend Requests',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  Spacer(),
                  if (_incomingRequests.isNotEmpty)
                    TextButton.icon(
                      onPressed: _toggleBulkMode,
                      icon: Icon(
                        _isBulkMode ? Icons.close : Icons.checklist,
                        size: 5.w,
                      ),
                      label: Text(
                        _isBulkMode ? 'Cancel' : 'Select',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
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
                labelStyle: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'Incoming (${_incomingRequests.length})'),
                  Tab(text: 'Outgoing (${_outgoingRequests.length})'),
                  Tab(text: 'Suggested'),
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
                        _buildIncomingTab(),
                        _buildOutgoingTab(),
                        _buildSuggestedTab(),
                      ],
                    ),
            ),

            // Bulk Action Bar
            if (_isBulkMode && _selectedRequests.isNotEmpty)
              BulkActionBarWidget(
                selectedCount: _selectedRequests.length,
                onAcceptAll: _acceptAllSelected,
                onDeclineAll: _declineAllSelected,
                onCancel: _toggleBulkMode,
              ),
          ],
        ),
        bottomNavigationBar: DualHeaderBottomBar(
          currentRoute: AppRoutes.friendRequestsHub,
          onNavigate: (route) {
            Navigator.pushNamed(context, route);
          },
        ),
      ),
    );
  }

  Widget _buildIncomingTab() {
    if (_incomingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 20.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No pending requests',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'New friend requests will appear here',
              style: GoogleFonts.inter(
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
      itemCount: _incomingRequests.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final request = _incomingRequests[index];
        final requestId = request['id'] as String;
        final isSelected = _selectedRequests.contains(requestId);

        return IncomingRequestCardWidget(
          request: request,
          isSelected: isSelected,
          isBulkMode: _isBulkMode,
          onToggleSelection: () => _toggleSelection(requestId),
          onAccept: () => _acceptRequest(requestId),
          onDecline: () => _declineRequest(requestId),
          onIgnore: () => _ignoreRequest(requestId),
        );
      },
    );
  }

  Widget _buildOutgoingTab() {
    if (_outgoingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 20.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No outgoing requests',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Requests you send will appear here',
              style: GoogleFonts.inter(
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
      itemCount: _outgoingRequests.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final request = _outgoingRequests[index];
        return OutgoingRequestCardWidget(
          request: request,
          onCancel: () => _cancelRequest(request['id']),
        );
      },
    );
  }

  Widget _buildSuggestedTab() {
    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: _suggestedFriends.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final user = _suggestedFriends[index];
        return SuggestedFriendCardWidget(
          user: user,
          onSendRequest: () => _sendFriendRequest(user['id']),
        );
      },
    );
  }

  void _showMutualFriends(Map<String, dynamic> request) async {
    final userId = request['requester']?['id'] ?? '';
    final mutualFriends = await _socialService.getMutualFriends(userId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MutualFriendsWidget(
        userId: userId,
        mutualCount: mutualFriends.length,
      ),
    );
  }
}