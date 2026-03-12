import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/platform_log.dart';
import '../../services/logging/log_stream_service.dart';
import './widgets/user_activity_card_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

class UserActivityLogViewer extends StatefulWidget {
  const UserActivityLogViewer({super.key});

  @override
  State<UserActivityLogViewer> createState() => _UserActivityLogViewerState();
}

class _UserActivityLogViewerState extends State<UserActivityLogViewer> {
  String selectedCategory = 'all';
  final List<String> categories = [
    'all',
    'voting',
    'payment',
    'security',
    'user_activity',
  ];
  final bool _isLoading = true;
  final List<PlatformLog> _activityLogs = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'UserActivityLogViewer',
      onRetry: () async {},
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('My Activity Log'),
          backgroundColor: Colors.blue[600],
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 10)
            : _activityLogs.isEmpty
            ? NoDataEmptyState(
                title: 'No Activity Logs',
                description: 'Your activity history will appear here.',
                onRefresh: () async {},
              )
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // Trigger rebuild to refresh stream
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _activityLogs.length,
                  itemBuilder: (context, index) {
                    return UserActivityCardWidget(log: _activityLogs[index]);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 8.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(category.replaceAll('_', ' ').toUpperCase()),
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
    );
  }

  Widget _buildLogStream() {
    return StreamBuilder<List<PlatformLog>>(
      stream: LogStreamService.getUserActivityStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading logs: ${snapshot.error}'));
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
              return UserActivityCardWidget(log: filteredLogs[index]);
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
            'No activity logs found',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
          Text('Your activity will appear here as you use the app'),
        ],
      ),
    );
  }
}
