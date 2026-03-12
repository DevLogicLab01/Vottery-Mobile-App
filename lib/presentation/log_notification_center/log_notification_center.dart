import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/platform_log.dart';
import '../../services/logging/log_stream_service.dart';
import './widgets/critical_alert_card_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

class LogNotificationCenter extends StatefulWidget {
  const LogNotificationCenter({super.key});

  @override
  State<LogNotificationCenter> createState() => _LogNotificationCenterState();
}

class _LogNotificationCenterState extends State<LogNotificationCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCategory = 'all';
  String selectedSeverity = 'all';
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool _isLoading = false;
  final List<PlatformLog> _logs = [];

  final List<String> categories = [
    'all',
    'security',
    'system',
    'performance',
    'fraud_detection',
  ];

  final List<String> severityLevels = ['all', 'critical', 'error', 'warn'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });
    // Simulate loading - in real implementation, fetch logs here
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'LogNotificationCenter',
      onRetry: _loadLogs,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Log Notification Center'),
          backgroundColor: Colors.red[700],
          actions: [
            IconButton(
              icon: Icon(Icons.mark_email_read),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: _openNotificationSettings,
              tooltip: 'Notification settings',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(Icons.warning_amber), text: 'Critical'),
              Tab(icon: Icon(Icons.security), text: 'Security'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCriticalAlertsTab(),
            _buildSecurityEventsTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<PlatformLog>>(
      stream: LogStreamService.getAdminLogStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonList(itemCount: 10);
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading history: ${snapshot.error}'),
          );
        }

        var logs = snapshot.data ?? [];

        // Apply filters
        logs = _applyFilters(logs);

        if (logs.isEmpty) {
          return NoDataEmptyState(
            title: 'No Log Notifications',
            description: 'System logs and notifications will appear here.',
            onRefresh: _loadLogs,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
          },
          child: ListView.builder(
            padding: EdgeInsets.all(3.w),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return CriticalAlertCardWidget(
                log: logs[index],
                onDismiss: () => _dismissAlert(logs[index].id),
                onTap: () => _showAlertDetails(logs[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(3.w),
      color: Colors.grey[100],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search notifications...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildSeverityFilter() {
    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: severityLevels.length,
        itemBuilder: (context, index) {
          final severity = severityLevels[index];
          final isSelected = severity == selectedSeverity;
          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(
                severity.toUpperCase(),
                style: TextStyle(fontSize: 10.sp),
              ),
              selected: isSelected,
              selectedColor: _getSeverityColor(severity),
              onSelected: (selected) {
                setState(() {
                  selectedSeverity = severity;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCriticalAlertsTab() {
    return StreamBuilder<List<PlatformLog>>(
      stream: LogStreamService.getCriticalAlertsStream(),
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
                Text('Error loading alerts: ${snapshot.error}'),
              ],
            ),
          );
        }

        var logs = snapshot.data ?? [];

        // Apply filters
        logs = _applyFilters(logs);

        if (logs.isEmpty) {
          return _buildEmptyState('No critical alerts', Icons.check_circle);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
          },
          child: ListView.builder(
            padding: EdgeInsets.all(3.w),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return CriticalAlertCardWidget(
                log: logs[index],
                onDismiss: () => _dismissAlert(logs[index].id),
                onTap: () => _showAlertDetails(logs[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSecurityEventsTab() {
    return StreamBuilder<List<PlatformLog>>(
      stream: LogStreamService.getAdminLogStream(logCategory: 'security'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading security events: ${snapshot.error}'),
          );
        }

        var logs = snapshot.data ?? [];

        // Apply filters
        logs = _applyFilters(logs);

        if (logs.isEmpty) {
          return _buildEmptyState(
            'No security events',
            Icons.security_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
          },
          child: ListView.builder(
            padding: EdgeInsets.all(3.w),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return CriticalAlertCardWidget(
                log: logs[index],
                onDismiss: () => _dismissAlert(logs[index].id),
                onTap: () => _showAlertDetails(logs[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            message,
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.h),
          Text(
            'All systems operating normally',
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
          .where((log) => log.logCategory == selectedCategory)
          .toList();
    }

    // Severity filter
    if (selectedSeverity != 'all') {
      filtered = filtered
          .where((log) => log.logLevel == selectedSeverity)
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

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'error':
        return Colors.orange;
      case 'warn':
        return Colors.yellow[700]!;
      default:
        return Colors.blue[300]!;
    }
  }

  void _markAllAsRead() {
    // TODO: Implement mark all as read functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('All notifications marked as read')));
  }

  void _openNotificationSettings() {
    // TODO: Navigate to notification settings
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Notification settings')));
  }

  void _dismissAlert(String logId) {
    // TODO: Implement dismiss functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Alert dismissed')));
  }

  void _showAlertDetails(PlatformLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAlertDetailsSheet(log),
    );
  }

  Widget _buildAlertDetailsSheet(PlatformLog log) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: _getSeverityColor(log.logLevel),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.white, size: 24.sp),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    log.eventType.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(log.message, style: TextStyle(fontSize: 12.sp)),
                  SizedBox(height: 2.h),
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildDetailRow('Category', log.logCategory),
                  _buildDetailRow('Severity', log.logLevel),
                  _buildDetailRow(
                    'Time',
                    log.createdAt.toString().substring(0, 19),
                  ),
                  if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'Metadata',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        log.metadata.toString(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 3.h),
                  Text(
                    'Automated Response Actions',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildActionButton(
                    'Investigate',
                    Icons.search,
                    Colors.blue,
                    () => _handleAction('investigate', log),
                  ),
                  SizedBox(height: 1.h),
                  _buildActionButton(
                    'Suspend Account',
                    Icons.block,
                    Colors.red,
                    () => _handleAction('suspend', log),
                  ),
                  SizedBox(height: 1.h),
                  _buildActionButton(
                    'Escalate to Admin',
                    Icons.arrow_upward,
                    Colors.orange,
                    () => _handleAction('escalate', log),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
        ),
      ),
    );
  }

  void _handleAction(String action, PlatformLog log) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action "$action" executed for alert')),
    );
    // TODO: Implement actual action handlers
  }
}
