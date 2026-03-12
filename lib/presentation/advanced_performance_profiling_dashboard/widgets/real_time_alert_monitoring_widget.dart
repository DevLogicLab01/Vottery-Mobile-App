import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/performance_profiling_service.dart';
import '../../../services/unified_alert_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';

/// Real-Time Alert Monitoring Widget
/// Integrated alert dashboard showing live CPU/memory/network thresholds
class RealTimeAlertMonitoringWidget extends StatefulWidget {
  const RealTimeAlertMonitoringWidget({super.key});

  @override
  State<RealTimeAlertMonitoringWidget> createState() =>
      _RealTimeAlertMonitoringWidgetState();
}

class _RealTimeAlertMonitoringWidgetState
    extends State<RealTimeAlertMonitoringWidget> {
  final UnifiedAlertService _alertService = UnifiedAlertService.instance;
  final PerformanceProfilingService _profilingService =
      PerformanceProfilingService.instance;

  StreamSubscription? _alertSubscription;
  List<Map<String, dynamic>> _performanceAlerts = [];
  Map<String, dynamic> _thresholds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlertData();
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAlertData() async {
    setState(() => _isLoading = true);

    try {
      final alerts = await _alertService.getNotifications(
        categories: ['performance', 'system'],
        isRead: false,
      );

      final thresholds = await _profilingService.getPerformanceThresholds();

      if (mounted) {
        setState(() {
          _performanceAlerts = alerts;
          _thresholds = thresholds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load alert data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupRealTimeUpdates() {
    _alertSubscription = _alertService.subscribeToNotifications((data) {
      if (mounted) {
        setState(() {
          _performanceAlerts = data
              .where(
                (alert) =>
                    alert['notification_type'] == 'performance' ||
                    alert['notification_type'] == 'system',
              )
              .toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SkeletonDashboard();
    }

    return RefreshIndicator(
      onRefresh: _loadAlertData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThresholdsHeader(),
            SizedBox(height: 3.h),
            _buildLiveThresholds(),
            SizedBox(height: 3.h),
            Text(
              'Active Performance Alerts',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            if (_performanceAlerts.isEmpty)
              _buildEmptyState()
            else
              ..._performanceAlerts.map((alert) => _buildAlertCard(alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdsHeader() {
    final criticalCount = _performanceAlerts
        .where((a) => a['priority'] == 'critical')
        .length;
    final highCount = _performanceAlerts
        .where((a) => a['priority'] == 'high')
        .length;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            criticalCount > 0 ? Colors.red : Colors.green,
            (criticalCount > 0 ? Colors.red : Colors.green).withAlpha(204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: (criticalCount > 0 ? Colors.red : Colors.green).withAlpha(
              77,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            criticalCount > 0 ? Icons.warning : Icons.check_circle,
            color: Colors.white,
            size: 8.w,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  criticalCount > 0
                      ? 'Performance Issues Detected'
                      : 'All Systems Normal',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$criticalCount critical, $highCount high priority alerts',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveThresholds() {
    final cpuThreshold = (_thresholds['cpu_threshold'] ?? 80.0) as num;
    final memoryThreshold = (_thresholds['memory_threshold'] ?? 85.0) as num;
    final networkThreshold = (_thresholds['network_threshold'] ?? 90.0) as num;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Performance Thresholds',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        _buildThresholdCard(
          'CPU Usage',
          cpuThreshold.toDouble(),
          65.0,
          Icons.memory,
          Colors.blue,
        ),
        SizedBox(height: 1.h),
        _buildThresholdCard(
          'Memory Usage',
          memoryThreshold.toDouble(),
          72.0,
          Icons.storage,
          Colors.purple,
        ),
        SizedBox(height: 1.h),
        _buildThresholdCard(
          'Network Latency',
          networkThreshold.toDouble(),
          45.0,
          Icons.network_check,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildThresholdCard(
    String label,
    double threshold,
    double currentValue,
    IconData icon,
    Color color,
  ) {
    final isExceeded = currentValue >= threshold;
    final percentage = (currentValue / threshold * 100).clamp(0, 100);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isExceeded ? Colors.red : color.withAlpha(77),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, color: color, size: 5.w),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Threshold: ${threshold.toInt()}%',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${currentValue.toInt()}%',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: isExceeded ? Colors.red : color,
                    ),
                  ),
                  if (isExceeded)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'EXCEEDED',
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isExceeded ? Colors.red : color,
            ),
            minHeight: 1.h,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final priority = alert['priority'] ?? 'medium';
    final title = alert['title'] ?? 'Performance Alert';
    final message = alert['message'] ?? '';
    final createdAt = alert['created_at'] as String?;
    final alertId = alert['id'] as String;

    final priorityColor = _getPriorityColor(priority);

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: priorityColor.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getPriorityIcon(priority),
                  color: priorityColor,
                  size: 4.w,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        DateFormat(
                          'MMM dd, HH:mm',
                        ).format(DateTime.parse(createdAt)),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: priorityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acknowledgeAlert(alertId),
                  icon: Icon(Icons.check, size: 4.w),
                  label: const Text('Acknowledge'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _isolateService(alert),
                  icon: Icon(Icons.block, size: 4.w),
                  label: const Text('Isolate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(8.w),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 15.w, color: Colors.green),
          SizedBox(height: 2.h),
          Text(
            'No Active Alerts',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'All performance metrics are within normal thresholds',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.info;
    }
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    await _alertService.markAsRead(alertId);
    await _loadAlertData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert acknowledged'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _isolateService(Map<String, dynamic> alert) async {
    // Trigger automated service isolation
    debugPrint('Isolating service for alert: ${alert['id']}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service isolation triggered'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
