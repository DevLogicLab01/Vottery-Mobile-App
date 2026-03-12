import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/platform_log.dart';
import '../../../services/logging/log_stream_service.dart';
import './critical_alert_card_widget.dart';

class NotificationHistoryWidget extends StatelessWidget {
  final String selectedCategory;
  final String searchQuery;

  const NotificationHistoryWidget({
    super.key,
    required this.selectedCategory,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PlatformLog>>(
      stream: LogStreamService.getAdminLogStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 2.h),
                Text('Error loading history: ${snapshot.error}'),
              ],
            ),
          );
        }

        var logs = snapshot.data ?? [];

        // Apply filters
        logs = _applyFilters(logs);

        if (logs.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            _buildStatsSummary(logs),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Trigger rebuild
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(3.w),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return CriticalAlertCardWidget(
                      log: logs[index],
                      onDismiss: () {},
                      onTap: () => _showLogDetails(context, logs[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsSummary(List<PlatformLog> logs) {
    final criticalCount = logs
        .where((log) => PlatformLogExtensions(log).severity == 'critical')
        .length;
    final errorCount = logs
        .where((log) => PlatformLogExtensions(log).severity == 'error')
        .length;
    final warnCount = logs
        .where((log) => PlatformLogExtensions(log).severity == 'warn')
        .length;

    return Container(
      padding: EdgeInsets.all(3.w),
      margin: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Summary',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Critical', criticalCount, Colors.red),
              _buildStatItem('Errors', errorCount, Colors.orange),
              _buildStatItem('Warnings', warnCount, Colors.yellow[700]!),
              _buildStatItem('Total', logs.length, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'No notification history',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.h),
          Text(
            'Past notifications will appear here',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  List<PlatformLog> _applyFilters(List<PlatformLog> logs) {
    var filtered = logs;

    // Category filter
    if (selectedCategory != 'all') {
      filtered = filtered
          .where((log) => log.eventType == selectedCategory)
          .toList();
    }

    // Search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (log) =>
                log.message.toLowerCase().contains(searchQuery.toLowerCase()) ||
                log.eventType.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  void _showLogDetails(BuildContext context, PlatformLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.eventType.replaceAll('_', ' ').toUpperCase()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 1.h),
              Text(log.message),
              SizedBox(height: 2.h),
              Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(log.eventType),
              SizedBox(height: 1.h),
              Text('Severity:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(PlatformLogExtensions(log).severity),
              SizedBox(height: 1.h),
              Text('Time:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(log.createdAt.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
