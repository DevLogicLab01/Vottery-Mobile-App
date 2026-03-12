import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/anomaly_detection_service.dart';
import '../../services/auth_service.dart';

class EnhancedPerformanceAnomalyDetectionDashboard extends StatefulWidget {
  const EnhancedPerformanceAnomalyDetectionDashboard({super.key});

  @override
  State<EnhancedPerformanceAnomalyDetectionDashboard> createState() =>
      _EnhancedPerformanceAnomalyDetectionDashboardState();
}

class _EnhancedPerformanceAnomalyDetectionDashboardState
    extends State<EnhancedPerformanceAnomalyDetectionDashboard> {
  final _anomalyService = AnomalyDetectionService.instance;
  final _authService = AuthService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _detectionStats = {};
  List<Map<String, dynamic>> _activeAnomalies = [];
  int _baselinePeriod = 30;
  double _thresholdPercentage = 150;
  String? _selectedAnomalyId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stats = await _anomalyService.getDetectionStatistics();
    final anomalies = await _anomalyService.getActiveAnomalies();

    setState(() {
      _detectionStats = stats;
      _activeAnomalies = anomalies;
      _isLoading = false;
    });
  }

  Future<void> _recalculateBaselines() async {
    setState(() => _isLoading = true);

    final success = await _anomalyService.calculateBaselines(
      periodDays: _baselinePeriod,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baselines recalculated successfully')),
      );
      await _loadData();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to recalculate baselines')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acknowledgeAnomaly(String anomalyId) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final success = await _anomalyService.acknowledgeAnomaly(
      anomalyId,
      userId,
      'Acknowledged from dashboard',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Anomaly acknowledged')));
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Anomaly Detection'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.all(3.w),
                children: [
                  _buildDetectionStatusCard(),
                  SizedBox(height: 2.h),
                  _buildBaselineConfigurationCard(),
                  SizedBox(height: 2.h),
                  _buildActiveAnomaliesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildDetectionStatusCard() {
    final anomaliesToday = _detectionStats['anomalies_detected_today'] ?? 0;
    final criticalCount = _detectionStats['critical_anomalies'] ?? 0;
    final detectionStatus = _detectionStats['detection_status'] ?? 'unknown';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radar, size: 24.sp, color: Colors.blue),
                SizedBox(width: 2.w),
                Text(
                  'Detection Status',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Status',
                    detectionStatus == 'active' ? 'Active' : 'Inactive',
                    detectionStatus == 'active' ? Colors.green : Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Last Check',
                    _formatTimestamp(_detectionStats['last_check']),
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Anomalies Today',
                    anomaliesToday.toString(),
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Critical',
                    criticalCount.toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 0.5.h),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 1.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBaselineConfigurationCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Baseline Configuration',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Text(
              'Baseline Period',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 1.h),
            DropdownButtonFormField<int>(
              initialValue: _baselinePeriod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 7, child: Text('7 days')),
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: 90, child: Text('90 days')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _baselinePeriod = value);
                }
              },
            ),
            SizedBox(height: 2.h),
            Text(
              'Anomaly Threshold: ${_thresholdPercentage.toInt()}%',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            Slider(
              value: _thresholdPercentage,
              min: 100,
              max: 300,
              divisions: 20,
              label: '${_thresholdPercentage.toInt()}%',
              onChanged: (value) {
                setState(() => _thresholdPercentage = value);
              },
            ),
            Text(
              'Alert when P95 latency exceeds ${_thresholdPercentage.toInt()}% of baseline',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _recalculateBaselines,
                icon: const Icon(Icons.calculate),
                label: const Text('Recalculate Baselines'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAnomaliesList() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Anomalies',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            if (_activeAnomalies.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 48.sp,
                        color: Colors.green,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'No active anomalies',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._activeAnomalies.map((anomaly) => _buildAnomalyCard(anomaly)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyCard(Map<String, dynamic> anomaly) {
    final severity = anomaly['severity'] as String;
    final operationName = anomaly['operation_name'] as String;
    final baselineP95 = (anomaly['baseline_p95_ms'] as num).toDouble();
    final currentP95 = (anomaly['current_p95_ms'] as num).toDouble();
    final deviation = (anomaly['deviation_percentage'] as num).toDouble();
    final detectedAt = anomaly['detected_at'] as String;

    final severityColor = _getSeverityColor(severity);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        border: Border.all(color: severityColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    operationName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'P95: ${currentP95.toStringAsFixed(0)}ms (baseline: ${baselineP95.toStringAsFixed(0)}ms)',
              style: TextStyle(fontSize: 12.sp),
            ),
            Text(
              '+${deviation.toStringAsFixed(1)}% deviation',
              style: TextStyle(
                fontSize: 12.sp,
                color: severityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Detected ${_formatTimestamp(detectedAt)}',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAnomalyDetails(anomaly),
                    child: const Text('View Details'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acknowledgeAnomaly(anomaly['anomaly_id']),
                    child: const Text('Acknowledge'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAnomalyDetails(Map<String, dynamic> anomaly) {
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
                    'Anomaly Details',
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
              _buildDetailRow('Operation', anomaly['operation_name']),
              _buildDetailRow('Severity', anomaly['severity'].toUpperCase()),
              _buildDetailRow(
                'Baseline P95',
                '${anomaly['baseline_p95_ms'].toStringAsFixed(0)}ms',
              ),
              _buildDetailRow(
                'Current P95',
                '${anomaly['current_p95_ms'].toStringAsFixed(0)}ms',
              ),
              _buildDetailRow(
                'Deviation',
                '+${anomaly['deviation_percentage'].toStringAsFixed(1)}%',
              ),
              _buildDetailRow(
                'Affected Requests',
                anomaly['affected_requests'].toString(),
              ),
              _buildDetailRow(
                'Detected At',
                _formatFullTimestamp(anomaly['detected_at']),
              ),
              SizedBox(height: 2.h),
              if (anomaly['impact_assessment'] != null) ...[
                Text(
                  'Impact Assessment',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  anomaly['impact_assessment'],
                  style: TextStyle(fontSize: 12.sp),
                ),
                SizedBox(height: 2.h),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _acknowledgeAnomaly(anomaly['anomaly_id']);
                  },
                  child: const Text('Acknowledge Anomaly'),
                ),
              ),
            ],
          ),
        ),
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
            width: 35.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
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

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else {
        return '${diff.inDays} days ago';
      }
    } catch (e) {
      return timestamp;
    }
  }

  String _formatFullTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
