import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/audit_log_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import 'package:timeago/timeago.dart' as timeago;

class ComprehensiveAuditLogViewer extends StatefulWidget {
  const ComprehensiveAuditLogViewer({super.key});

  @override
  State<ComprehensiveAuditLogViewer> createState() =>
      _ComprehensiveAuditLogViewerState();
}

class _ComprehensiveAuditLogViewerState
    extends State<ComprehensiveAuditLogViewer> {
  final AuditLogService _auditService = AuditLogService.instance;

  List<Map<String, dynamic>> _auditLogs = [];
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _verificationHistory = [];

  bool _isLoading = true;
  bool _isVerifying = false;
  double _verificationProgress = 0.0;

  // Filters
  final Set<String> _selectedEventTypes = {
    'security_policy_change',
    'incident_resolution',
    'playbook_execution',
    'escalation_decision',
  };
  final Set<String> _selectedActionTypes = {
    'create',
    'read',
    'update',
    'delete',
    'execute',
  };
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _tamperFilter;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
    _loadStatistics();
    _loadVerificationHistory();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _auditService.getAuditLogs(
        eventTypes: _selectedEventTypes.toList(),
        actionTypes: _selectedActionTypes.toList(),
        startDate: _startDate,
        endDate: _endDate,
        tamperDetected: _tamperFilter,
        limit: 500,
      );
      setState(() {
        _auditLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load audit logs error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _auditService.getAuditLogStatistics();
      setState(() => _statistics = stats);
    } catch (e) {
      debugPrint('Load statistics error: $e');
    }
  }

  Future<void> _loadVerificationHistory() async {
    try {
      final history = await _auditService.getVerificationHistory(limit: 10);
      setState(() => _verificationHistory = history);
    } catch (e) {
      debugPrint('Load verification history error: $e');
    }
  }

  Future<void> _verifyIntegrity() async {
    setState(() {
      _isVerifying = true;
      _verificationProgress = 0.0;
    });

    try {
      // Simulate progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() => _verificationProgress = i / 100);
      }

      final result = await _auditService.verifyAuditLogIntegrity();

      setState(() => _isVerifying = false);

      if (result['success']) {
        _showVerificationResultDialog(result);
        _loadAuditLogs();
        _loadVerificationHistory();
      }
    } catch (e) {
      debugPrint('Verify integrity error: $e');
      setState(() => _isVerifying = false);
    }
  }

  void _showVerificationResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result['tampered_entries'] == 0
                  ? Icons.check_circle
                  : Icons.warning,
              color: result['tampered_entries'] == 0
                  ? Colors.green
                  : Colors.red,
            ),
            SizedBox(width: 2.w),
            const Text('Verification Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entries Verified: ${result['entries_verified']}'),
            Text('Tampered Entries: ${result['tampered_entries']}'),
            Text('Hash Chain Status: ${result['hash_chain_status']}'),
            if (result['tampered_entries'] > 0) ...[
              SizedBox(height: 1.h),
              const Text(
                'Warning: Tampering detected! Forensic analysis required.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (result['tampered_entries'] > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _tamperFilter = true);
                _loadAuditLogs();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('View Tampered Entries'),
            ),
        ],
      ),
    );
  }

  Future<void> _exportAuditLogs() async {
    try {
      final csv = await _auditService.exportAuditLogsToCsv(
        startDate: _startDate,
        endDate: _endDate,
        eventTypes: _selectedEventTypes.toList(),
        includeHashValues: true,
      );

      if (csv.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit log exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Export audit logs error: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    return _auditLogs.where((log) {
      if (_searchQuery.isNotEmpty) {
        final reason = (log['reason'] as String? ?? '').toLowerCase();
        final actor = (log['actor_username'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!reason.contains(query) && !actor.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'Comprehensive Audit Log Viewer',
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Comprehensive Audit Log Viewer',
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportAuditLogs,
            ),
          ],
        ),
        body: _isLoading
            ? const ShimmerSkeletonLoader(child: SkeletonDashboard())
            : RefreshIndicator(
                onRefresh: _loadAuditLogs,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatisticsCards(),
                      SizedBox(height: 2.h),
                      _buildVerificationSection(),
                      SizedBox(height: 2.h),
                      _buildSearchBar(),
                      SizedBox(height: 2.h),
                      _buildAuditLogList(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audit Log Statistics',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          height: 12.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStatCard(
                'Total Entries',
                _statistics['total_entries']?.toString() ?? '0',
                Icons.list_alt,
                Colors.blue,
              ),
              SizedBox(width: 3.w),
              _buildStatCard(
                'Entries Today',
                _statistics['entries_today']?.toString() ?? '0',
                Icons.today,
                Colors.green,
              ),
              SizedBox(width: 3.w),
              _buildStatCard(
                'Tampered',
                _statistics['tampered_entries']?.toString() ?? '0',
                Icons.warning,
                Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 35.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 6.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green, size: 6.w),
                SizedBox(width: 2.w),
                Text(
                  'Hash Chain Verification',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (_isVerifying) ...[
              LinearProgressIndicator(value: _verificationProgress),
              SizedBox(height: 1.h),
              Text(
                'Verifying ${(_verificationProgress * 100).toInt()}%...',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _verifyIntegrity,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Verify Audit Log Integrity'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 6.h),
                ),
              ),
              if (_verificationHistory.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  'Last Verification:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                ..._verificationHistory
                    .take(3)
                    .map(
                      (v) => Padding(
                        padding: EdgeInsets.only(bottom: 0.5.h),
                        child: Row(
                          children: [
                            Icon(
                              v['tampering_detected'] == true
                                  ? Icons.error
                                  : Icons.check_circle,
                              color: v['tampering_detected'] == true
                                  ? Colors.red
                                  : Colors.green,
                              size: 4.w,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                '${v['entries_verified']} entries verified - ${timeago.format(DateTime.parse(v['verification_timestamp']))}',
                                style: TextStyle(fontSize: 11.sp),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search audit logs...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
    );
  }

  Widget _buildAuditLogList() {
    if (_filteredLogs.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Icon(Icons.history, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No audit logs found',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audit Trail (${_filteredLogs.length} entries)',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        ..._filteredLogs.map((log) => _buildAuditLogCard(log)),
      ],
    );
  }

  Widget _buildAuditLogCard(Map<String, dynamic> log) {
    final eventType = log['event_type'] as String;
    final actionType = log['action_type'] as String;
    final actor = log['actor_username'] as String? ?? 'Unknown';
    final timestamp = DateTime.parse(log['event_timestamp']);
    final reason = log['reason'] as String? ?? 'No reason provided';
    final tamperDetected = log['tamper_detected'] as bool? ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: tamperDetected ? 4 : 1,
      color: tamperDetected ? Colors.red.withAlpha(26) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: tamperDetected
            ? const BorderSide(color: Colors.red, width: 2.0)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showAuditLogDetails(log),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _getEventTypeColor(eventType).withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  _getEventTypeIcon(eventType),
                  color: _getEventTypeColor(eventType),
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            eventType.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 13.sp,
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
                            color: _getActionTypeColor(actionType),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            actionType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'By: $actor',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      reason,
                      style: TextStyle(fontSize: 12.sp),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        if (tamperDetected)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: Colors.white,
                                  size: 3.w,
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
                          Icon(Icons.verified, color: Colors.green, size: 4.w),
                        const Spacer(),
                        Text(
                          timeago.format(timestamp),
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAuditLogDetails(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Audit Log Details',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildDetailRow('Event Type', log['event_type']),
              _buildDetailRow('Action', log['action_type']),
              _buildDetailRow('Actor', log['actor_username']),
              _buildDetailRow('Entity Type', log['entity_type']),
              _buildDetailRow('Entity ID', log['entity_id'] ?? 'N/A'),
              _buildDetailRow(
                'Timestamp',
                DateTime.parse(log['event_timestamp']).toString(),
              ),
              _buildDetailRow('Reason', log['reason'] ?? 'N/A'),
              SizedBox(height: 2.h),
              Text(
                'Cryptographic Verification',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              _buildDetailRow('Hash', log['cryptographic_hash']),
              _buildDetailRow('Previous Hash', log['previous_hash']),
              _buildDetailRow(
                'Status',
                log['tamper_detected'] == true ? 'TAMPERED' : 'VERIFIED',
              ),
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
              const Text('Event Types'),
              ..._buildEventTypeCheckboxes(),
              SizedBox(height: 2.h),
              const Text('Action Types'),
              ..._buildActionTypeCheckboxes(),
              SizedBox(height: 2.h),
              const Text('Tamper Status'),
              RadioListTile<bool?>(
                title: const Text('All'),
                value: null,
                groupValue: _tamperFilter,
                onChanged: (value) => setState(() => _tamperFilter = value),
              ),
              RadioListTile<bool?>(
                title: const Text('Verified Only'),
                value: false,
                groupValue: _tamperFilter,
                onChanged: (value) => setState(() => _tamperFilter = value),
              ),
              RadioListTile<bool?>(
                title: const Text('Tampered Only'),
                value: true,
                groupValue: _tamperFilter,
                onChanged: (value) => setState(() => _tamperFilter = value),
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
              _loadAuditLogs();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventTypeCheckboxes() {
    return [
      'security_policy_change',
      'incident_resolution',
      'playbook_execution',
      'escalation_decision',
    ].map((type) {
      return CheckboxListTile(
        title: Text(type.replaceAll('_', ' ').toUpperCase()),
        value: _selectedEventTypes.contains(type),
        onChanged: (checked) {
          setState(() {
            if (checked == true) {
              _selectedEventTypes.add(type);
            } else {
              _selectedEventTypes.remove(type);
            }
          });
        },
      );
    }).toList();
  }

  List<Widget> _buildActionTypeCheckboxes() {
    return ['create', 'read', 'update', 'delete', 'execute'].map((type) {
      return CheckboxListTile(
        title: Text(type.toUpperCase()),
        value: _selectedActionTypes.contains(type),
        onChanged: (checked) {
          setState(() {
            if (checked == true) {
              _selectedActionTypes.add(type);
            } else {
              _selectedActionTypes.remove(type);
            }
          });
        },
      );
    }).toList();
  }

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'security_policy_change':
        return Colors.red;
      case 'incident_resolution':
        return Colors.orange;
      case 'playbook_execution':
        return Colors.purple;
      case 'escalation_decision':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(String type) {
    switch (type) {
      case 'security_policy_change':
        return Icons.policy;
      case 'incident_resolution':
        return Icons.check_circle;
      case 'playbook_execution':
        return Icons.play_arrow;
      case 'escalation_decision':
        return Icons.arrow_upward;
      default:
        return Icons.event;
    }
  }

  Color _getActionTypeColor(String type) {
    switch (type) {
      case 'create':
        return Colors.green;
      case 'read':
        return Colors.blue;
      case 'update':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      case 'execute':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
