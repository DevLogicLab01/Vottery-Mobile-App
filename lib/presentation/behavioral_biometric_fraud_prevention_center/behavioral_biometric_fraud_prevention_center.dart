import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/fraud_detection_service.dart';
import '../../services/multi_ai_orchestration_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/behavioral_authentication_scoring_widget.dart';
import './widgets/device_fingerprinting_widget.dart';
import './widgets/keystroke_dynamics_analysis_widget.dart';
import './widgets/multi_factor_risk_scoring_widget.dart';
import './widgets/session_anomaly_detection_widget.dart';

class BehavioralBiometricFraudPreventionCenter extends StatefulWidget {
  const BehavioralBiometricFraudPreventionCenter({super.key});

  @override
  State<BehavioralBiometricFraudPreventionCenter> createState() =>
      _BehavioralBiometricFraudPreventionCenterState();
}

class _BehavioralBiometricFraudPreventionCenterState
    extends State<BehavioralBiometricFraudPreventionCenter>
    with SingleTickerProviderStateMixin {
  final FraudDetectionService _fraudService = FraudDetectionService.instance;
  final MultiAIOrchestrationService _orchestrator =
      MultiAIOrchestrationService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _biometricOverview = {};
  List<Map<String, dynamic>> _activeSessions = [];
  List<Map<String, dynamic>> _anomalyAlerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadBiometricData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricData() async {
    setState(() => _isLoading = true);

    try {
      // Mock data - in production, load from fraud detection service
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _biometricOverview = {
          'active_sessions': 247,
          'fraud_confidence_score': 94.2,
          'anomaly_alerts': 12,
          'behavioral_patterns_analyzed': 1543,
        };
        _activeSessions = [
          {
            'user_id': 'user_123',
            'session_id': 'session_abc',
            'typing_pattern_score': 87.5,
            'device_fingerprint': 'fp_xyz789',
            'risk_level': 'low',
            'started_at': DateTime.now().subtract(const Duration(minutes: 15)),
          },
          {
            'user_id': 'user_456',
            'session_id': 'session_def',
            'typing_pattern_score': 45.2,
            'device_fingerprint': 'fp_abc123',
            'risk_level': 'high',
            'started_at': DateTime.now().subtract(const Duration(minutes: 8)),
          },
        ];
        _anomalyAlerts = [
          {
            'alert_id': 'alert_1',
            'user_id': 'user_789',
            'anomaly_type': 'typing_pattern_deviation',
            'severity': 'high',
            'confidence': 0.89,
            'detected_at': DateTime.now().subtract(const Duration(minutes: 5)),
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load biometric data error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'BehavioralBiometricFraudPreventionCenter',
      onRetry: _loadBiometricData,
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
          title: 'Biometric Fraud Prevention',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadBiometricData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildOverviewHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        KeystrokeDynamicsAnalysisWidget(
                          sessions: _activeSessions,
                        ),
                        DeviceFingerprintingWidget(sessions: _activeSessions),
                        BehavioralAuthenticationScoringWidget(
                          sessions: _activeSessions,
                        ),
                        SessionAnomalyDetectionWidget(
                          anomalyAlerts: _anomalyAlerts,
                        ),
                        MultiFactorRiskScoringWidget(sessions: _activeSessions),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewHeader() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.people,
            label: 'Active Sessions',
            value: _biometricOverview['active_sessions'].toString(),
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.security,
            label: 'Confidence Score',
            value: '${_biometricOverview['fraud_confidence_score']}%',
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.warning,
            label: 'Anomaly Alerts',
            value: _biometricOverview['anomaly_alerts'].toString(),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 8.w, color: color),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: AppTheme.textSecondaryLight),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Keystroke'),
          Tab(text: 'Device'),
          Tab(text: 'Scoring'),
          Tab(text: 'Anomalies'),
          Tab(text: 'Risk'),
        ],
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          ShimmerSkeletonLoader(
            child: Container(
              height: 15.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          ShimmerSkeletonLoader(
            child: Container(
              height: 20.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          ShimmerSkeletonLoader(
            child: Container(
              height: 15.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
