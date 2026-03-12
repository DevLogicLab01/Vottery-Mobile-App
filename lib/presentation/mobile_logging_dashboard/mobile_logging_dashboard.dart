import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/platform_log.dart';
import '../../services/logging/log_stream_service.dart';
import './widgets/log_entry_card_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';

class MobileLoggingDashboard extends StatefulWidget {
  const MobileLoggingDashboard({super.key});

  @override
  State<MobileLoggingDashboard> createState() => _MobileLoggingDashboardState();
}

class _MobileLoggingDashboardState extends State<MobileLoggingDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCategory = 'all';
  String? selectedLogLevel;
  final List<String> categories = [
    'all',
    'voting',
    'payment',
    'security',
    'user_activity',
    'ai_analysis',
    'performance',
    'fraud_detection',
    'system',
  ];

  final List<String> logLevels = ['debug', 'info', 'warn', 'error', 'critical'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'MobileLoggingDashboard',
      onRetry: () => setState(() {}), // trigger rebuild to refresh logs
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Mobile Logging Dashboard'),
          backgroundColor: Colors.blue[600],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(Icons.stream), text: 'Live Logs'),
              Tab(icon: Icon(Icons.computer), text: 'System'),
              Tab(icon: Icon(Icons.security), text: 'Security'),
              Tab(icon: Icon(Icons.person), text: 'Activity'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLogStream(null),
                  _buildLogStream('system'),
                  _buildLogStream('security'),
                  _buildLogStream('user_activity'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(2.w),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Filter',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 5.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: FilterChip(
                    label: Text(
                      category.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontSize: 10.sp),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.yellow[600],
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Log Level',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 5.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: logLevels.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: FilterChip(
                      label: Text('ALL', style: TextStyle(fontSize: 10.sp)),
                      selected: selectedLogLevel == null,
                      selectedColor: Colors.blue[300],
                      onSelected: (selected) {
                        setState(() {
                          selectedLogLevel = null;
                        });
                      },
                    ),
                  );
                }
                final level = logLevels[index - 1];
                final isSelected = level == selectedLogLevel;
                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: FilterChip(
                    label: Text(
                      level.toUpperCase(),
                      style: TextStyle(fontSize: 10.sp),
                    ),
                    selected: isSelected,
                    selectedColor: _getLogLevelColor(level),
                    onSelected: (selected) {
                      setState(() {
                        selectedLogLevel = selected ? level : null;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogStream(String? categoryFilter) {
    return StreamBuilder<List<PlatformLog>>(
      stream: LogStreamService.getAdminLogStream(
        logLevel: selectedLogLevel,
        logCategory: categoryFilter,
      ),
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
                Text('Error loading logs: ${snapshot.error}'),
              ],
            ),
          );
        }

        final logs = snapshot.data ?? [];
        final filteredLogs = selectedCategory == 'all'
            ? logs
            : logs.where((log) => log.logCategory == selectedCategory).toList();

        if (filteredLogs.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild to refresh stream
          },
          child: ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) {
              return LogEntryCardWidget(log: filteredLogs[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'No logs found',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
          Text('Logs will appear here as system events occur'),
        ],
      ),
    );
  }

  Color _getLogLevelColor(String level) {
    switch (level) {
      case 'critical':
        return Colors.red;
      case 'error':
        return Colors.orange;
      case 'warn':
        return Colors.yellow[700]!;
      case 'info':
        return Colors.blue;
      case 'debug':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
