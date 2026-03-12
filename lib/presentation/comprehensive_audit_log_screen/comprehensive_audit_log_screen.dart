import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';
import '../../services/audit_log_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import 'package:timeago/timeago.dart' as timeago;

class ComprehensiveAuditLogScreen extends StatefulWidget {
  const ComprehensiveAuditLogScreen({super.key});

  @override
  State<ComprehensiveAuditLogScreen> createState() =>
      _ComprehensiveAuditLogScreenState();
}

class _ComprehensiveAuditLogScreenState
    extends State<ComprehensiveAuditLogScreen> {
  final AuditLogService _auditService = AuditLogService.instance;
  bool _isLoading = true;
  bool _isVerifying = false;
  List<Map<String, dynamic>> _auditLogs = [];
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic>? _verificationResult;

  // Filters
  final Set<String> _selectedEventTypes = {
    'security_policy_change',
    'incident_resolution',
    'playbook_execution',
    'escalation_decision',
  };
  final Set<String> _selectedActionTypes = {
    'create',
    'update',
    'delete',
    'execute',
  };
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _auditService.getAuditLogs(
          eventTypes: _selectedEventTypes.toList(),
          actionTypes: _selectedActionTypes.toList(),
        ),
        _auditService.getAuditLogStatistics(),
      ]);

      setState(() {
        _auditLogs = results[0] as List<Map<String, dynamic>>;
        _statistics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyIntegrity() async {
    setState(() => _isVerifying = true);
    try {
      final result = await _auditService.verifyAuditLogIntegrity();
      setState(() {
        _verificationResult = result;
        _isVerifying = false;
      });

      if (mounted) {
        _showVerificationResults(result);
      }
    } catch (e) {
      debugPrint('Verify integrity error: $e');
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ComprehensiveAuditLogScreen',
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF632CA6),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comprehensive Audit Log',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Immutable audit trail with cryptographic verification',
                style: TextStyle(color: Colors.white70, fontSize: 11.sp),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _showSearchDialog,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: _isLoading ? _buildLoadingState() : _buildContent(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isVerifying ? null : _verifyIntegrity,
          backgroundColor: const Color(0xFF632CA6),
          icon: _isVerifying
              ? const SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                )
              : const Icon(Icons.verified_user),
          label: Text(_isVerifying ? 'Verifying...' : 'Verify Integrity'),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: 5,
      itemBuilder: (context, index) => ShimmerSkeletonLoader(
        child: Container(
          height: 12.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildStatisticsHeader(),
        Expanded(
          child: _auditLogs.isEmpty ? _buildEmptyState() : _buildAuditLogList(),
        ),
      ],
    );
  }

  Widget _buildStatisticsHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: const BoxDecoration(
        color: Color(0xFF632CA6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Entries',
              '${_statistics['total_entries'] ?? 0}',
              Icons.list_alt,
              Colors.blue,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              'Today',
              '${_statistics['entries_today'] ?? 0}',
              Icons.today,
              Colors.green,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              'Tampered',
              '${_statistics['tampered_entries'] ?? 0}',
              Icons.warning,
              _statistics['tampered_entries'] == 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 10.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(3.w),
        itemCount: _auditLogs.length,
        itemBuilder: (context, index) {
          final log = _auditLogs[index];
          return _buildAuditLogCard(log);
        },
      ),
    );
  }

  Widget _buildAuditLogCard(Map<String, dynamic> log) {
    final eventType = log['event_type'] as String;
    final actionType = log['action_type'] as String;
    final actorUsername = log['actor_username'] as String;
    final timestamp = DateTime.parse(log['event_timestamp']);
    final tampered = log['tamper_detected'] as bool? ?? false;

    return GestureDetector(
      onTap: () => _showLogDetails(log),
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          color: tampered ? Colors.red[50] : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border(
            left: BorderSide(
              color: tampered ? Colors.red : _getActionColor(actionType),
              width: 4.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: _getActionColor(actionType).withAlpha(26),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      _getActionIcon(actionType),
                      color: _getActionColor(actionType),
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventType.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'by $actorUsername',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tampered)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.white,
                            size: 14.0,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'TAMPERED',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Icon(Icons.verified, color: Colors.green, size: 20.0),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  _buildActionBadge(actionType),
                  SizedBox(width: 2.w),
                  Text(
                    timeago.format(timestamp),
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14.0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBadge(String action) {
    final color = _getActionColor(action);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        action.toUpperCase(),
        style: TextStyle(
          fontSize: 9.sp,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 20.w, color: Colors.grey[400]),
          SizedBox(height: 2.h),
          Text(
            'No audit logs found',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'execute':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'execute':
        return Icons.play_arrow;
      default:
        return Icons.info;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Audit Logs'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by actor or reason...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => _searchQuery = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Audit Logs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Event Types',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 2.w,
                children:
                    [
                          'security_policy_change',
                          'incident_resolution',
                          'playbook_execution',
                          'escalation_decision',
                        ]
                        .map(
                          (e) => FilterChip(
                            label: Text(e.replaceAll('_', ' ')),
                            selected: _selectedEventTypes.contains(e),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedEventTypes.add(e);
                                } else {
                                  _selectedEventTypes.remove(e);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showLogDetails(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(4.w),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Audit Log Details',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              _buildDetailRow('Event Type', log['event_type']),
              _buildDetailRow('Action', log['action_type']),
              _buildDetailRow('Actor', log['actor_username']),
              _buildDetailRow('Entity Type', log['entity_type']),
              _buildDetailRow(
                'Timestamp',
                DateTime.parse(log['event_timestamp']).toString(),
              ),
              if (log['reason'] != null)
                _buildDetailRow('Reason', log['reason']),
              SizedBox(height: 2.h),
              Text(
                'Cryptographic Hash',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  log['cryptographic_hash'],
                  style: TextStyle(fontSize: 10.sp, fontFamily: 'monospace'),
                ),
              ),
              if (log['old_value'] != null || log['new_value'] != null) ...[
                SizedBox(height: 2.h),
                Text(
                  'Changes',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                if (log['old_value'] != null)
                  _buildJsonView('Old Value', log['old_value']),
                if (log['new_value'] != null)
                  _buildJsonView('New Value', log['new_value']),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonView(String label, dynamic jsonData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 0.5.h),
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            const JsonEncoder.withIndent('  ').convert(jsonData),
            style: TextStyle(fontSize: 10.sp, fontFamily: 'monospace'),
          ),
        ),
        SizedBox(height: 1.h),
      ],
    );
  }

  void _showVerificationResults(Map<String, dynamic> result) {
    final success = result['success'] as bool;
    final totalEntries = result['total_entries'] as int;
    final tamperedEntries = result['tampered_entries'] as int;
    final durationMs = result['duration_ms'] as int;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              tamperedEntries == 0 ? Icons.check_circle : Icons.warning,
              color: tamperedEntries == 0 ? Colors.green : Colors.red,
            ),
            SizedBox(width: 2.w),
            const Text('Verification Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Entries Verified: $totalEntries'),
            Text(
              'Tampered Entries: $tamperedEntries',
              style: TextStyle(
                color: tamperedEntries == 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Duration: ${durationMs}ms'),
            if (tamperedEntries > 0) ...[
              SizedBox(height: 2.h),
              Text(
                'WARNING: Tampering detected! Immediate investigation required.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (tamperedEntries > 0)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Show tampered entries
                _loadData();
              },
              child: const Text('View Tampered Entries'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
