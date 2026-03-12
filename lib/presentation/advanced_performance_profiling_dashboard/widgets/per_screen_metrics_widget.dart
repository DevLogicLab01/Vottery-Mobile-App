import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../services/performance_profiling_service.dart';
import '../../../theme/app_theme.dart';

class PerScreenMetricsWidget extends StatefulWidget {
  const PerScreenMetricsWidget({super.key});

  @override
  State<PerScreenMetricsWidget> createState() => _PerScreenMetricsWidgetState();
}

class _PerScreenMetricsWidgetState extends State<PerScreenMetricsWidget> {
  final PerformanceProfilingService _profilingService =
      PerformanceProfilingService.instance;

  String _selectedScreen = 'vote_casting';
  List<Map<String, dynamic>> _metrics = [];
  bool _isLoading = false;

  final List<String> _screens = [
    'vote_casting',
    'vote_discovery',
    'create_vote',
    'vote_results',
    'user_profile',
    'social_media_home_feed',
  ];

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    final metrics = await _profilingService.getScreenPerformanceMetrics(
      screenName: _selectedScreen,
      hours: 24,
    );

    setState(() {
      _metrics = metrics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenSelector(),
          SizedBox(height: 2.h),
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_metrics.isEmpty)
            _buildEmptyState()
          else ...[
            _buildMetricsSummary(),
            SizedBox(height: 2.h),
            _buildMetricsChart(),
            SizedBox(height: 2.h),
            _buildDetailedMetrics(),
          ],
        ],
      ),
    );
  }

  Widget _buildScreenSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedScreen,
      decoration: InputDecoration(
        labelText: 'Select Screen',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        prefixIcon: Icon(Icons.screen_search_desktop, size: 5.w),
      ),
      items: _screens.map((screen) {
        return DropdownMenuItem(
          value: screen,
          child: Text(screen.replaceAll('_', ' ').toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedScreen = value!;
        });
        _loadMetrics();
      },
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No metrics available',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 1.h),
            Text(
              'Start profiling to collect performance data',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSummary() {
    final avgCpu =
        _metrics
            .map((m) => m['cpu_usage_percentage'] as num)
            .reduce((a, b) => a + b) /
        _metrics.length;
    final avgMemory =
        _metrics
            .map((m) => m['memory_usage_mb'] as num)
            .reduce((a, b) => a + b) /
        _metrics.length;
    final avgFps =
        _metrics.map((m) => m['fps'] as num).reduce((a, b) => a + b) /
        _metrics.length;
    final avgLoadTime =
        _metrics.map((m) => m['load_time_ms'] as num).reduce((a, b) => a + b) /
        _metrics.length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Metrics (24h)',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                _buildMetricTile(
                  icon: Icons.memory,
                  label: 'CPU',
                  value: '${avgCpu.toStringAsFixed(1)}%',
                  color: avgCpu > 70 ? Colors.red : Colors.green,
                ),
                SizedBox(width: 2.w),
                _buildMetricTile(
                  icon: Icons.storage,
                  label: 'Memory',
                  value: '${avgMemory.toStringAsFixed(0)}MB',
                  color: avgMemory > 500 ? Colors.red : Colors.green,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                _buildMetricTile(
                  icon: Icons.speed,
                  label: 'FPS',
                  value: avgFps.toStringAsFixed(1),
                  color: avgFps < 45 ? Colors.red : Colors.green,
                ),
                SizedBox(width: 2.w),
                _buildMetricTile(
                  icon: Icons.timer,
                  label: 'Load Time',
                  value: '${avgLoadTime.toStringAsFixed(0)}ms',
                  color: avgLoadTime > 2000 ? Colors.red : Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 6.w),
            SizedBox(height: 1.h),
            Text(
              value,
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  'Chart visualization would go here',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Measurements',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _metrics.take(5).length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final metric = _metrics[index];
                return ListTile(
                  leading: Icon(Icons.analytics, color: AppTheme.accentLight),
                  title: Text(
                    'CPU: ${metric['cpu_usage_percentage']}% | Memory: ${metric['memory_usage_mb']}MB',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  subtitle: Text(
                    'FPS: ${metric['fps']} | Load: ${metric['load_time_ms']}ms',
                    style: TextStyle(fontSize: 9.sp),
                  ),
                  trailing: Text(
                    _formatTimestamp(metric['timestamp']),
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    final dt = DateTime.parse(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
