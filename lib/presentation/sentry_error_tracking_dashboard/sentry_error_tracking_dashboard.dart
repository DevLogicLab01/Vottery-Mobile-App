import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';

class SentryErrorTrackingDashboard extends StatefulWidget {
  const SentryErrorTrackingDashboard({super.key});

  @override
  State<SentryErrorTrackingDashboard> createState() =>
      _SentryErrorTrackingDashboardState();
}

class _SentryErrorTrackingDashboardState
    extends State<SentryErrorTrackingDashboard> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentErrors = [];
  Map<String, dynamic> _errorStats = {};

  @override
  void initState() {
    super.initState();
    _loadErrorData();
  }

  Future<void> _loadErrorData() async {
    setState(() => _isLoading = true);
    try {
      // Load error statistics from Supabase
      final response = await _supabaseService.client
          .from('error_tracking_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _recentErrors = List<Map<String, dynamic>>.from(response);
          _calculateStats();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayErrors = _recentErrors.where((error) {
      final createdAt = DateTime.parse(error['created_at']);
      return createdAt.isAfter(today);
    }).length;

    final uniqueUsers = _recentErrors
        .map((e) => e['user_id'])
        .where((id) => id != null)
        .toSet()
        .length;

    final criticalErrors = _recentErrors
        .where((e) => e['severity'] == 'fatal' || e['severity'] == 'error')
        .length;

    setState(() {
      _errorStats = {
        'todayErrors': todayErrors,
        'uniqueUsers': uniqueUsers,
        'criticalErrors': criticalErrors,
        'crashFreeRate': _calculateCrashFreeRate(),
      };
    });
  }

  double _calculateCrashFreeRate() {
    if (_recentErrors.isEmpty) return 100.0;
    final crashes = _recentErrors
        .where((e) => e['error_type'] == 'crash')
        .length;
    return ((1 - (crashes / _recentErrors.length)) * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Tracking Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadErrorData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadErrorData,
              child: ListView(
                padding: EdgeInsets.all(3.w),
                children: [
                  _buildStatsOverview(),
                  SizedBox(height: 2.h),
                  _buildErrorList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Error Overview',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Errors Today',
                '${_errorStats['todayErrors'] ?? 0}',
                Icons.error_outline,
                Colors.red,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildStatCard(
                'Crash-Free Rate',
                '${(_errorStats['crashFreeRate'] ?? 100).toStringAsFixed(1)}%',
                Icons.check_circle_outline,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Critical Errors',
                '${_errorStats['criticalErrors'] ?? 0}',
                Icons.warning_amber,
                Colors.orange,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildStatCard(
                'Affected Users',
                '${_errorStats['uniqueUsers'] ?? 0}',
                Icons.people_outline,
                Colors.blue,
              ),
            ),
          ],
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              title,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Errors',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        if (_recentErrors.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(4.h),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 60, color: Colors.green),
                  SizedBox(height: 2.h),
                  Text(
                    'No errors reported',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ..._recentErrors.take(20).map((error) => _buildErrorCard(error)),
      ],
    );
  }

  Widget _buildErrorCard(Map<String, dynamic> error) {
    final severity = error['severity'] ?? 'info';
    final errorType = error['error_type'] ?? 'unknown';
    final message = error['error_message'] ?? 'No message';
    final timestamp = DateTime.parse(error['created_at']);
    final timeAgo = _formatTimeAgo(timestamp);

    Color severityColor;
    IconData severityIcon;

    switch (severity) {
      case 'fatal':
        severityColor = Colors.red;
        severityIcon = Icons.dangerous;
        break;
      case 'error':
        severityColor = Colors.orange;
        severityIcon = Icons.error;
        break;
      case 'warning':
        severityColor = Colors.yellow;
        severityIcon = Icons.warning;
        break;
      default:
        severityColor = Colors.blue;
        severityIcon = Icons.info;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Icon(severityIcon, color: severityColor, size: 30),
        title: Text(
          errorType,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.5.h),
            Text(
              message,
              style: TextStyle(fontSize: 12.sp),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => _showErrorDetails(error),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  void _showErrorDetails(Map<String, dynamic> error) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(4.w),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Error Details',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildDetailRow('Error Type', error['error_type'] ?? 'Unknown'),
              _buildDetailRow('Severity', error['severity'] ?? 'info'),
              _buildDetailRow(
                'Message',
                error['error_message'] ?? 'No message',
              ),
              _buildDetailRow('Screen', error['screen_name'] ?? 'Unknown'),
              _buildDetailRow('User ID', error['user_id'] ?? 'Anonymous'),
              _buildDetailRow('Device', error['device_info'] ?? 'Unknown'),
              _buildDetailRow('App Version', error['app_version'] ?? 'Unknown'),
              _buildDetailRow('Timestamp', error['created_at'] ?? 'Unknown'),
              if (error['stack_trace'] != null) ...[
                SizedBox(height: 2.h),
                Text(
                  'Stack Trace',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    error['stack_trace'],
                    style: TextStyle(fontSize: 10.sp, fontFamily: 'monospace'),
                  ),
                ),
              ],
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _markAsResolved(error['id']);
                },
                icon: const Icon(Icons.check),
                label: const Text('Mark as Resolved'),
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
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsResolved(String errorId) async {
    try {
      await _supabaseService.client
          .from('error_tracking_logs')
          .update({
            'status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', errorId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error marked as resolved')),
        );
        _loadErrorData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }
}
