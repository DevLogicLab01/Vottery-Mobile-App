import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/fraud_detection_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Advanced Fraud Detection Center - Multi-AI consensus fraud detection
/// Automated scoring, alerts, and investigation workflows
class AdvancedFraudDetectionCenter extends StatefulWidget {
  const AdvancedFraudDetectionCenter({super.key});

  @override
  State<AdvancedFraudDetectionCenter> createState() =>
      _AdvancedFraudDetectionCenterState();
}

class _AdvancedFraudDetectionCenterState
    extends State<AdvancedFraudDetectionCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _fraudAlerts = [];
  List<Map<String, dynamic>> _fraudHistory = [];
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFraudData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFraudData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        FraudDetectionService.instance.getFraudAlerts(unresolved: true),
        FraudDetectionService.instance.getFraudHistory(limit: 50),
        FraudDetectionService.instance.getFraudStatistics(),
      ]);

      setState(() {
        _fraudAlerts = results[0] as List<Map<String, dynamic>>;
        _fraudHistory = results[1] as List<Map<String, dynamic>>;
        _statistics = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AdvancedFraudDetectionCenter',
      onRetry: _loadFraudData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Fraud Detection',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadFraudData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _fraudAlerts.isEmpty
            ? NoDataEmptyState(
                title: 'No Fraud Alerts',
                description: 'Fraud detection alerts will appear here.',
                onRefresh: _loadFraudData,
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStatisticsHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAlertsTab(),
                          _buildHistoryTab(),
                          _buildAnalyticsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatisticsHeader() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Critical',
              _statistics['critical_alerts']?.toString() ?? '0',
              Colors.red,
              'error',
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildStatCard(
              'High',
              _statistics['high_alerts']?.toString() ?? '0',
              Colors.orange,
              'warning',
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildStatCard(
              'Resolved',
              _statistics['resolved_alerts']?.toString() ?? '0',
              Colors.green,
              'check_circle',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    String iconName,
  ) {
    return Column(
      children: [
        CustomIconWidget(iconName: iconName, size: 8.w, color: color),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(12.0),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        tabs: [
          Tab(text: 'Alerts (${_fraudAlerts.length})'),
          Tab(text: 'History'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    if (_fraudAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              size: 20.w,
              color: Colors.green,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Active Alerts',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'All fraud detections resolved',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _fraudAlerts.length,
      itemBuilder: (context, index) {
        final alert = _fraudAlerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'medium';
    final fraudScore = (alert['fraud_score'] ?? 0.0).toDouble();

    Color severityColor;
    switch (severity) {
      case 'critical':
        severityColor = Colors.red;
        break;
      case 'high':
        severityColor = Colors.orange;
        break;
      case 'medium':
        severityColor = Colors.yellow[700]!;
        break;
      default:
        severityColor = Colors.blue;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: severityColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
              Spacer(),
              Text(
                '${fraudScore.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            alert['description'] ?? 'Fraud detected',
            style: TextStyle(fontSize: 14.sp, color: AppTheme.textPrimaryLight),
          ),
          SizedBox(height: 1.h),
          Text(
            'Action: ${alert['recommended_action'] ?? 'Review required'}',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _resolveAlert(alert['id'], 'investigated'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                  child: Text('Resolve', style: TextStyle(fontSize: 14.sp)),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _resolveAlert(alert['id'], 'false_positive'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryLight),
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                  child: Text(
                    'False Positive',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _fraudHistory.length,
      itemBuilder: (context, index) {
        final detection = _fraudHistory[index];
        return _buildHistoryCard(detection);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> detection) {
    final fraudScore = (detection['fraud_score'] ?? 0.0).toDouble();
    final severity = detection['severity'] ?? 'low';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fraud Score: ${fraudScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Severity: $severity',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: 'history',
            size: 6.w,
            color: AppTheme.textSecondaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fraud Detection Analytics',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildAnalyticsCard(
            'Average Fraud Score',
            '${(_statistics['average_fraud_score'] ?? 0.0).toStringAsFixed(1)}%',
            'analytics',
          ),
          SizedBox(height: 2.h),
          _buildAnalyticsCard(
            'Total Detections',
            _statistics['total_detections']?.toString() ?? '0',
            'security',
          ),
          SizedBox(height: 2.h),
          _buildAnalyticsCard(
            'Resolution Rate',
            '${_calculateResolutionRate()}%',
            'check_circle',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String label, String value, String iconName) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            size: 10.w,
            color: AppTheme.primaryLight,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveAlert(String alertId, String resolution) async {
    final success = await FraudDetectionService.instance.resolveFraudAlert(
      alertId: alertId,
      resolution: resolution,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Alert resolved successfully')));
      _loadFraudData();
    }
  }

  double _calculateResolutionRate() {
    final total = _statistics['total_detections'] ?? 0;
    final resolved = _statistics['resolved_alerts'] ?? 0;
    if (total == 0) return 0.0;
    return (resolved / total * 100);
  }
}
