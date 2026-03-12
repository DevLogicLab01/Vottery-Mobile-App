import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/sms_rate_limiter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../theme/app_theme.dart';

/// SMS Queue Management Dashboard
/// Intelligent queue visualization with priority controls, retry management,
/// and real-time processing metrics
class SMSQueueManagementDashboard extends StatefulWidget {
  const SMSQueueManagementDashboard({super.key});

  @override
  State<SMSQueueManagementDashboard> createState() =>
      _SMSQueueManagementDashboardState();
}

class _SMSQueueManagementDashboardState
    extends State<SMSQueueManagementDashboard> {
  final SMSQueueManager _queueManager = SMSQueueManager.instance;

  Map<String, dynamic> _queueStats = {};
  List<Map<String, dynamic>> _queuedMessages = [];
  bool _isLoading = true;
  String _selectedStatus = 'pending';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadQueueData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadQueueData(),
    );
  }

  Future<void> _loadQueueData() async {
    final stats = await _queueManager.getQueueStatistics();
    final messages = await _queueManager.getQueuedMessages(
      status: _selectedStatus,
      limit: 50,
    );

    if (mounted) {
      setState(() {
        _queueStats = stats;
        _queuedMessages = messages;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'SMS Queue Management',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'SMS Queue Management',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Column(
          children: [
            _buildStatsHeader(),
            _buildStatusFilter(),
            Expanded(child: _buildQueueList()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(3.w),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Pending',
              '${_queueStats['pending_count'] ?? 0}',
              Colors.orange,
              Icons.schedule,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              'Processing',
              '${_queueStats['processing_count'] ?? 0}',
              Colors.blue,
              Icons.sync,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              'Failed',
              '${_queueStats['failed_count'] ?? 0}',
              Colors.red,
              Icons.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          _buildFilterChip('pending', 'Pending'),
          SizedBox(width: 2.w),
          _buildFilterChip('processing', 'Processing'),
          SizedBox(width: 2.w),
          _buildFilterChip('failed', 'Failed'),
          const Spacer(),
          IconButton(
            onPressed: _loadQueueData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatus = status);
        _loadQueueData();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textPrimaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildQueueList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_queuedMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48.sp, color: AppTheme.textSecondary),
            SizedBox(height: 2.h),
            Text(
              'No messages in queue',
              style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _queuedMessages.length,
      itemBuilder: (context, index) {
        final message = _queuedMessages[index];
        return _buildMessageCard(message);
      },
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final priority = message['priority'] as String;
    final status = message['status'] as String;
    final retryCount = message['retry_count'] as int? ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(priority),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              if (retryCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Retry $retryCount/3',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'To: ${message['recipient_phone']}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            message['message_body'],
            style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (status == 'failed') ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _retryMessage(message['queue_id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(0, 5.h),
                    ),
                    child: Text('Retry', style: TextStyle(fontSize: 12.sp)),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _deleteMessage(message['queue_id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: Size(0, 5.h),
                    ),
                    child: Text('Delete', style: TextStyle(fontSize: 12.sp)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Future<void> _retryMessage(String queueId) async {
    await _queueManager.retryFailedMessage(queueId);
    _loadQueueData();
  }

  Future<void> _deleteMessage(String queueId) async {
    await _queueManager.deleteQueuedMessage(queueId);
    _loadQueueData();
  }
}