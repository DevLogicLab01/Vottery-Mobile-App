import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../services/performance_profiling_service.dart';
import '../../../theme/app_theme.dart';

class ScreenMetricsWidget extends StatefulWidget {
  final String screenName;

  const ScreenMetricsWidget({super.key, required this.screenName});

  @override
  State<ScreenMetricsWidget> createState() => _ScreenMetricsWidgetState();
}

class _ScreenMetricsWidgetState extends State<ScreenMetricsWidget> {
  final PerformanceProfilingService _profilingService =
      PerformanceProfilingService.instance;

  List<Map<String, dynamic>> _metrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  @override
  void didUpdateWidget(ScreenMetricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenName != widget.screenName) {
      _loadMetrics();
    }
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    final metrics = <Map<String, dynamic>>[];

    setState(() {
      _metrics = metrics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_metrics.isEmpty) {
      return Center(
        child: Text(
          'No metrics available for this screen',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 12.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      );
    }

    final latestMetric = _metrics.first;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCard(
            'CPU Usage',
            '${latestMetric['cpu_usage_percentage']?.toStringAsFixed(1) ?? '0'}%',
            Icons.memory,
            Colors.blue,
            _getCpuStatus(latestMetric['cpu_usage_percentage']),
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Memory (Heap + Stack)',
            '${((latestMetric['memory_heap_mb'] ?? 0) + (latestMetric['memory_stack_mb'] ?? 0)).toStringAsFixed(1)} MB',
            Icons.storage,
            Colors.purple,
            _getMemoryStatus(
              (latestMetric['memory_heap_mb'] ?? 0) +
                  (latestMetric['memory_stack_mb'] ?? 0),
            ),
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Network Bandwidth',
            '${latestMetric['network_bandwidth_mbps']?.toStringAsFixed(2) ?? '0'} MB/s',
            Icons.network_check,
            Colors.orange,
            _getNetworkStatus(latestMetric['network_bandwidth_mbps']),
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Frame Rate',
            '${latestMetric['frames_per_second']?.toStringAsFixed(1) ?? '0'} FPS',
            Icons.speed,
            Colors.green,
            _getFpsStatus(latestMetric['frames_per_second']),
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Frame Render Time',
            '${latestMetric['frame_render_time_ms']?.toStringAsFixed(1) ?? '0'} ms',
            Icons.timer,
            Colors.teal,
            'Normal',
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Widget Rebuilds',
            '${latestMetric['widget_rebuild_count'] ?? 0}',
            Icons.refresh,
            Colors.indigo,
            'Normal',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String status,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, size: 8.w, color: color),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              status,
              style: google_fonts.GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCpuStatus(double? cpu) {
    if (cpu == null) return 'Unknown';
    if (cpu > 90) return 'Critical';
    if (cpu > 70) return 'High';
    if (cpu > 50) return 'Medium';
    return 'Normal';
  }

  String _getMemoryStatus(double memory) {
    if (memory > 1000) return 'Critical';
    if (memory > 500) return 'High';
    if (memory > 300) return 'Medium';
    return 'Normal';
  }

  String _getNetworkStatus(double? network) {
    if (network == null) return 'Unknown';
    if (network > 10) return 'Critical';
    if (network > 5) return 'High';
    if (network > 3) return 'Medium';
    return 'Normal';
  }

  String _getFpsStatus(double? fps) {
    if (fps == null) return 'Unknown';
    if (fps < 30) return 'Critical';
    if (fps < 45) return 'High';
    if (fps < 55) return 'Medium';
    return 'Normal';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow.shade700;
      case 'Normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
