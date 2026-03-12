import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Groups Collaborative Election Creation + Member Leaderboards
class GroupsCollaborativeElectionHub extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupsCollaborativeElectionHub({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupsCollaborativeElectionHub> createState() =>
      _GroupsCollaborativeElectionHubState();
}

class _GroupsCollaborativeElectionHubState
    extends State<GroupsCollaborativeElectionHub>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _pendingElections = [];
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic>? _currentDraft;

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
      await Future.wait([
        _loadMembers(),
        _loadPendingElections(),
        _loadLeaderboard(),
      ]);
    } catch (e) {
      debugPrint('Load data error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMembers() async {
    try {
      final result = await _supabase
          .from('group_members')
          .select('user_id, role, user_profiles(display_name, avatar_url)')
          .eq('group_id', widget.groupId);
      if (mounted) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(result);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _members = [
            {
              'user_id': '1',
              'role': 'admin',
              'user_profiles': {'display_name': 'Alice Johnson'},
            },
            {
              'user_id': '2',
              'role': 'co_creator',
              'user_profiles': {'display_name': 'Bob Smith'},
            },
            {
              'user_id': '3',
              'role': 'reviewer',
              'user_profiles': {'display_name': 'Carol Davis'},
            },
          ];
        });
      }
    }
  }

  Future<void> _loadPendingElections() async {
    try {
      final result = await _supabase
          .from('election_drafts')
          .select()
          .eq('group_id', widget.groupId)
          .eq('status', 'pending_approval');
      if (mounted) {
        setState(() {
          _pendingElections = List<Map<String, dynamic>>.from(result);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingElections = [
            {
              'id': 'draft_1',
              'title': 'Best Community Initiative 2026',
              'created_by': 'Alice Johnson',
              'status': 'pending_approval',
              'created_at': DateTime.now()
                  .subtract(const Duration(hours: 2))
                  .toIso8601String(),
            },
          ];
        });
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final result = await _supabase
          .from('group_member_leaderboard')
          .select()
          .eq('group_id', widget.groupId)
          .order('score', ascending: false)
          .limit(10);
      if (mounted) {
        setState(() {
          _leaderboard = List<Map<String, dynamic>>.from(result);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _leaderboard = [
            {
              'rank': 1,
              'member_name': 'Alice Johnson',
              'score': 1250,
              'elections_created': 8,
              'votes_attracted': 450,
              'badges': ['top_creator', 'community_leader'],
            },
            {
              'rank': 2,
              'member_name': 'Bob Smith',
              'score': 980,
              'elections_created': 5,
              'votes_attracted': 320,
              'badges': ['active_member'],
            },
            {
              'rank': 3,
              'member_name': 'Carol Davis',
              'score': 720,
              'elections_created': 3,
              'votes_attracted': 210,
              'badges': ['reviewer'],
            },
          ];
        });
      }
    }
  }

  Future<void> _approveElection(String draftId) async {
    try {
      await _supabase
          .from('election_drafts')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', draftId);
      await _loadPendingElections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Election approved and published'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Approve election error: $e');
    }
  }

  Future<void> _rejectElection(String draftId) async {
    try {
      await _supabase
          .from('election_drafts')
          .update({'status': 'rejected'})
          .eq('id', draftId);
      await _loadPendingElections();
    } catch (e) {
      debugPrint('Reject election error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: widget.groupName,
      ),
      body: _isLoading
          ? const ShimmerSkeletonLoader(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 11.sp),
                  labelColor: AppTheme.primaryLight,
                  unselectedLabelColor: AppTheme.textSecondaryLight,
                  indicatorColor: AppTheme.primaryLight,
                  tabs: [
                    const Tab(text: 'Members & Roles'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Approval Queue'),
                          if (_pendingElections.isNotEmpty) ...[
                            SizedBox(width: 1.w),
                            Container(
                              padding: EdgeInsets.all(1.w),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${_pendingElections.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 8.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Tab(text: 'Leaderboard'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMembersTab(),
                      _buildApprovalQueueTab(),
                      _buildLeaderboardTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          '/election-creation-studio',
          arguments: {'group_id': widget.groupId},
        ),
        backgroundColor: AppTheme.primaryLight,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Election',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    final roles = ['Creator', 'Co-Creator', 'Reviewer'];
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Member Roles',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          ..._members.map((member) => _buildMemberCard(member)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final profile = member['user_profiles'] as Map<String, dynamic>? ?? {};
    final role = member['role'] ?? 'member';
    final roleColor = role == 'admin'
        ? Colors.red
        : role == 'co_creator'
        ? Colors.blue
        : Colors.green;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 5.w,
            backgroundColor: AppTheme.primaryLight.withAlpha(30),
            child: Text(
              (profile['display_name'] ?? 'U')[0].toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryLight,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              profile['display_name'] ?? 'Unknown',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: roleColor.withAlpha(20),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: roleColor.withAlpha(80)),
            ),
            child: Text(
              role.replaceAll('_', ' ').toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: roleColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalQueueTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Approval (${_pendingElections.length})',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          if (_pendingElections.isEmpty)
            Center(
              child: Text(
                'No elections pending approval',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            )
          else
            ..._pendingElections.map(
              (election) => Container(
                margin: EdgeInsets.only(bottom: 1.5.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(10),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.orange.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      election['title'] ?? 'Untitled Election',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'By: ${election['created_by'] ?? 'Unknown'}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _rejectElection(election['id']),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: Text(
                              'Reject',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _approveElection(election['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: Text(
                              'Approve',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Member Performance Leaderboard',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          ..._leaderboard.asMap().entries.map(
            (entry) => _buildLeaderboardCard(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(int index, Map<String, dynamic> member) {
    final rank = member['rank'] ?? (index + 1);
    final rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
        ? const Color(0xFFC0C0C0)
        : rank == 3
        ? const Color(0xFFCD7F32)
        : Colors.grey;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: rank <= 3
              ? rankColor.withAlpha(100)
              : Colors.grey.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: rankColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: rankColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['member_name'] ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  '${member['elections_created'] ?? 0} elections • '
                  '${member['votes_attracted'] ?? 0} votes',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${member['score'] ?? 0} pts',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}