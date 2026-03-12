import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/fraud_detection_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/threat_assessment_header_widget.dart';
import './widgets/predictive_fraud_scoring_widget.dart';
import './widgets/behavioral_pattern_recognition_widget.dart';
import './widgets/real_time_threat_prevention_widget.dart';
import './widgets/cross_platform_correlation_widget.dart';
import './widgets/fraud_prevention_card_widget.dart';
import './widgets/predictive_modeling_dashboard_widget.dart';
import './widgets/emergency_response_protocol_widget.dart';

class AiAnomalyDetectionFraudPreventionHub extends StatefulWidget {
  const AiAnomalyDetectionFraudPreventionHub({super.key});

  @override
  State<AiAnomalyDetectionFraudPreventionHub> createState() =>
      _AiAnomalyDetectionFraudPreventionHubState();
}

class _AiAnomalyDetectionFraudPreventionHubState
    extends State<AiAnomalyDetectionFraudPreventionHub> {
  bool _isLoading = true;
  Map<String, dynamic> _threatData = {};
  List<Map<String, dynamic>> _fraudAlerts = [];
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final alerts = await FraudDetectionService.instance.getFraudAlerts(
        unresolved: true,
      );
      final stats = await FraudDetectionService.instance.getFraudStatistics();

      setState(() {
        _fraudAlerts = alerts;
        _statistics = stats;
        _threatData = {
          'current_risk_level': _calculateRiskLevel(alerts),
          'active_investigations': alerts.length,
          'predictive_confidence': 0.87,
          'threat_count': alerts.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _calculateRiskLevel(List<Map<String, dynamic>> alerts) {
    if (alerts.isEmpty) return 'low';
    final criticalCount = alerts
        .where((a) => a['severity'] == 'critical')
        .length;
    if (criticalCount > 0) return 'critical';
    final highCount = alerts.where((a) => a['severity'] == 'high').length;
    if (highCount > 2) return 'high';
    return 'medium';
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AI Anomaly Detection & Fraud Prevention Hub',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'AI Anomaly Detection & Fraud Prevention',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ThreatAssessmentHeaderWidget(threatData: _threatData),
                      SizedBox(height: 2.h),
                      Text(
                        'Detection Systems',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      PredictiveFraudScoringWidget(statistics: _statistics),
                      SizedBox(height: 2.h),
                      BehavioralPatternRecognitionWidget(
                        statistics: _statistics,
                      ),
                      SizedBox(height: 2.h),
                      RealTimeThreatPreventionWidget(alerts: _fraudAlerts),
                      SizedBox(height: 2.h),
                      CrossPlatformCorrelationWidget(statistics: _statistics),
                      SizedBox(height: 2.h),
                      Text(
                        'Active Threats',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ..._fraudAlerts.map(
                        (alert) => Padding(
                          padding: EdgeInsets.only(bottom: 1.h),
                          child: FraudPreventionCardWidget(
                            alert: alert,
                            onAction: _handleFraudAction,
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      PredictiveModelingDashboardWidget(
                        statistics: _statistics,
                      ),
                      SizedBox(height: 2.h),
                      EmergencyResponseProtocolWidget(
                        onEmergencyAction: _handleEmergencyAction,
                      ),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          ShimmerSkeletonLoader(
            child: SizedBox(height: 15.h, width: double.infinity),
          ),
          SizedBox(height: 2.h),
          ShimmerSkeletonLoader(
            child: SizedBox(height: 20.h, width: double.infinity),
          ),
          SizedBox(height: 2.h),
          ShimmerSkeletonLoader(
            child: SizedBox(height: 20.h, width: double.infinity),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFraudAction(String alertId, String action) async {
    try {
      await FraudDetectionService.instance.resolveFraudAlert(
        alertId: alertId,
        resolution: action,
        notes: 'Action taken from fraud prevention hub',
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action executed: $action')));

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to execute action: $e')));
    }
  }

  Future<void> _handleEmergencyAction(String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Emergency Action'),
        content: Text('Are you sure you want to execute: $action?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emergency action initiated: $action')),
      );
    }
  }
}
