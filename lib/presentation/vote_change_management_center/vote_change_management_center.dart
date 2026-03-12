import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../services/vote_change_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class VoteChangeManagementCenter extends StatefulWidget {
  const VoteChangeManagementCenter({super.key});

  @override
  State<VoteChangeManagementCenter> createState() =>
      _VoteChangeManagementCenterState();
}

class _VoteChangeManagementCenterState extends State<VoteChangeManagementCenter>
    with SingleTickerProviderStateMixin {
  final _voteChangeService = VoteChangeService();
  final _supabase = SupabaseService.instance.client;

  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingChanges = [];
  List<Map<String, dynamic>> _changeHistory = [];
  List<Map<String, dynamic>> _auditFlags = [];
  Map<String, dynamic>? _analytics;
  String? _selectedElectionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get user's elections
      final elections = await _supabase
          .from('elections')
          .select('id')
          .eq('created_by', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (elections != null) {
        _selectedElectionId = elections['id'] as String;

        // Load all data
        await Future.wait([
          _loadPendingChanges(),
          _loadChangeHistory(),
          _loadAuditFlags(),
          _loadAnalytics(),
        ]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingChanges() async {
    if (_selectedElectionId == null) return;

    final changes = await _voteChangeService.getPendingChangeRequests(
      _selectedElectionId!,
    );
    setState(() => _pendingChanges = changes);
  }

  Future<void> _loadChangeHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final history = await _voteChangeService.getVoteChangeHistory(userId);
    setState(() => _changeHistory = history);
  }

  Future<void> _loadAuditFlags() async {
    if (_selectedElectionId == null) return;

    final flags = await _voteChangeService.getAuditFlags(_selectedElectionId!);
    setState(() => _auditFlags = flags);
  }

  Future<void> _loadAnalytics() async {
    if (_selectedElectionId == null) return;

    final analytics = await _voteChangeService.getVoteChangeAnalytics(
      _selectedElectionId!,
    );
    setState(() => _analytics = analytics);
  }

  Future<void> _approveChange(String changeHistoryId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final result = await _voteChangeService.approveVoteChange(
      changeHistoryId,
      userId,
    );

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote change approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _rejectChange(String changeHistoryId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final result = await _voteChangeService.rejectVoteChange(
      changeHistoryId,
      userId,
    );

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote change rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      await _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'VoteChangeManagementCenter',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Vote Change Management'),
          backgroundColor: Colors.deepOrange,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
              Tab(text: 'History', icon: Icon(Icons.history)),
              Tab(text: 'Audit', icon: Icon(Icons.flag)),
              Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingChangesTab(),
                  _buildChangeHistoryTab(),
                  _buildAuditFlagsTab(),
                  _buildAnalyticsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildPendingChangesTab() {
    if (_pendingChanges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80.sp, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No pending vote changes',
              style: TextStyle(fontSize: 18.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _pendingChanges.length,
      itemBuilder: (context, index) {
        final change = _pendingChanges[index];
        return _buildPendingChangeCard(change);
      },
    );
  }

  Widget _buildPendingChangeCard(Map<String, dynamic> change) {
    final userProfile = change['user_profiles'] as Map<String, dynamic>?;
    final userName = userProfile?['full_name'] as String? ?? 'Unknown User';
    final originalChoice = change['original_choice'] as String? ?? 'Unknown';
    final newChoice = change['new_choice'] as String? ?? 'Unknown';
    final requestedAt = change['requested_at'] as String?;
    final timeoutAt = change['timeout_at'] as String?;

    DateTime? timeoutDate;
    if (timeoutAt != null) {
      timeoutDate = DateTime.parse(timeoutAt);
    }

    final hoursRemaining = timeoutDate != null
        ? timeoutDate.difference(DateTime.now()).inHours
        : 0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepOrange.shade100,
                  child: Text(
                    userName[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (requestedAt != null)
                        Text(
                          'Requested ${_formatDateTime(requestedAt)}',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (hoursRemaining > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: hoursRemaining < 6
                          ? Colors.red.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '${hoursRemaining}h left',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: hoursRemaining < 6 ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original Choice:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    originalChoice,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  const Icon(Icons.arrow_downward, size: 16),
                  SizedBox(height: 1.h),
                  Text(
                    'New Choice:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    newChoice,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _approveChange(change['change_history_id']),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectChange(change['change_history_id']),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeHistoryTab() {
    if (_changeHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80.sp, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No change history',
              style: TextStyle(fontSize: 18.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _changeHistory.length,
      itemBuilder: (context, index) {
        final history = _changeHistory[index];
        return _buildHistoryCard(history);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    final election = history['elections'] as Map<String, dynamic>?;
    final electionTitle = election?['title'] as String? ?? 'Unknown Election';
    final status = history['status'] as String? ?? 'unknown';
    final changeTimestamp = history['change_timestamp'] as String?;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'timeout_approved':
        statusColor = Colors.blue;
        statusIcon = Icons.timer;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 1,
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor, size: 32.sp),
        title: Text(
          electionTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${status.toUpperCase()}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
            if (changeTimestamp != null)
              Text(
                _formatDateTime(changeTimestamp),
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildAuditFlagsTab() {
    if (_auditFlags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 80.sp, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No audit flags',
              style: TextStyle(fontSize: 18.sp, color: Colors.grey),
            ),
            Text(
              'All vote change attempts are compliant',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _auditFlags.length,
      itemBuilder: (context, index) {
        final flag = _auditFlags[index];
        return _buildAuditFlagCard(flag);
      },
    );
  }

  Widget _buildAuditFlagCard(Map<String, dynamic> flag) {
    final userProfile = flag['user_profiles'] as Map<String, dynamic>?;
    final userName = userProfile?['full_name'] as String? ?? 'Unknown User';
    final flagReason = flag['flag_reason'] as String? ?? 'unknown';
    final severity = flag['severity'] as String? ?? 'medium';
    final attemptTimestamp = flag['attempt_timestamp'] as String?;

    Color severityColor;
    switch (severity) {
      case 'critical':
        severityColor = Colors.red.shade900;
        break;
      case 'high':
        severityColor = Colors.red;
        break;
      case 'medium':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.yellow.shade700;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: severityColor, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: severityColor, size: 24.sp),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    userName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Reason: ${flagReason.replaceAll('_', ' ').toUpperCase()}',
              style: TextStyle(fontSize: 14.sp),
            ),
            if (attemptTimestamp != null)
              Text(
                'Attempted: ${_formatDateTime(attemptTimestamp)}',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analytics == null) {
      return const Center(child: Text('No analytics available'));
    }

    final totalRequests = _analytics!['total_change_requests'] as int? ?? 0;
    final approvedChanges = _analytics!['approved_changes'] as int? ?? 0;
    final rejectedChanges = _analytics!['rejected_changes'] as int? ?? 0;
    final timeoutApprovals = _analytics!['timeout_approvals'] as int? ?? 0;

    final approvalRate = totalRequests > 0
        ? (approvedChanges / totalRequests * 100).toStringAsFixed(1)
        : '0.0';

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vote Change Analytics',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 3.h),
          _buildAnalyticsCard(
            'Total Requests',
            totalRequests.toString(),
            Icons.all_inbox,
            Colors.blue,
          ),
          _buildAnalyticsCard(
            'Approved',
            approvedChanges.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          _buildAnalyticsCard(
            'Rejected',
            rejectedChanges.toString(),
            Icons.cancel,
            Colors.red,
          ),
          _buildAnalyticsCard(
            'Timeout Approvals',
            timeoutApprovals.toString(),
            Icons.timer,
            Colors.orange,
          ),
          SizedBox(height: 2.h),
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approval Rate',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '$approvalRate%',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32.sp),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM d, y h:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }
}
