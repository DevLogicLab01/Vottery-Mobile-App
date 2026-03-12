import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import './widgets/integration_status_panel_widget.dart';
import './widgets/system_config_panel_widget.dart';
import './widgets/feature_validation_panel_widget.dart';
import './widgets/performance_metrics_panel_widget.dart';
import './widgets/readiness_score_gauge_widget.dart';
import './widgets/launch_recommendation_card_widget.dart';

class MobileLaunchReadinessChecklist extends StatefulWidget {
  const MobileLaunchReadinessChecklist({super.key});
  @override
  State<MobileLaunchReadinessChecklist> createState() =>
      _MobileLaunchReadinessChecklistState();
}

class _MobileLaunchReadinessChecklistState
    extends State<MobileLaunchReadinessChecklist>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _integrationScore = 0;
  int _configScore = 0;
  int _featureScore = 0;
  int _performanceScore = 0;

  int get _overallScore =>
      (_integrationScore * 0.30 +
              _configScore * 0.25 +
              _featureScore * 0.25 +
              _performanceScore * 0.20)
          .round();

  Map<String, int> get _componentScores => {
    'Integration (30%)': _integrationScore,
    'Configuration (25%)': _configScore,
    'Features (25%)': _featureScore,
    'Performance (20%)': _performanceScore,
  };

  List<String> get _issues {
    final issues = <String>[];
    if (_integrationScore < 90) {
      issues.add('Some API integrations need verification');
    }
    if (_configScore < 90) {
      issues.add('Biometric auth configuration incomplete');
    }
    if (_featureScore < 90) issues.add('2 screens failed load time validation');
    if (_performanceScore < 90) {
      issues.add('Bundle size exceeds 35MB target (38.2MB)');
    }
    if (_overallScore < 75) {
      issues.add('Cold start time slightly above 2.0s target');
    }
    return issues;
  }

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

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF report...'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _runFullTestSuite() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Running full test suite across all tabs...'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Launch Readiness Checklist',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11.sp),
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF3B82F6),
          tabs: const [
            Tab(text: 'Integration Status'),
            Tab(text: 'System Config'),
            Tab(text: 'Feature Validation'),
            Tab(text: 'Performance'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Readiness',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      LinearProgressIndicator(
                        value: _overallScore / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _overallScore >= 90
                              ? const Color(0xFF10B981)
                              : _overallScore >= 75
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444),
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 3.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                  decoration: BoxDecoration(
                    color: _overallScore >= 90
                        ? const Color(0xFF10B981)
                        : _overallScore >= 75
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '$_overallScore%',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      IntegrationStatusPanelWidget(
                        onStatusUpdate: (data) => setState(
                          () => _integrationScore = data['score'] as int? ?? 0,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ReadinessScoreGaugeWidget(
                        score: _integrationScore,
                        componentScores: {
                          'Integration Score': _integrationScore,
                        },
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      SystemConfigPanelWidget(
                        onStatusUpdate: (data) => setState(
                          () => _configScore = data['score'] as int? ?? 0,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ReadinessScoreGaugeWidget(
                        score: _configScore,
                        componentScores: {'Config Score': _configScore},
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      FeatureValidationPanelWidget(
                        onStatusUpdate: (data) => setState(
                          () => _featureScore = data['score'] as int? ?? 0,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ReadinessScoreGaugeWidget(
                        score: _featureScore,
                        componentScores: {'Feature Score': _featureScore},
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      PerformanceMetricsPanelWidget(
                        onStatusUpdate: (data) => setState(
                          () => _performanceScore = data['score'] as int? ?? 0,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ReadinessScoreGaugeWidget(
                        score: _overallScore,
                        componentScores: _componentScores,
                      ),
                      SizedBox(height: 3.h),
                      LaunchRecommendationCardWidget(
                        score: _overallScore,
                        issues: _issues,
                        onExportReport: _exportReport,
                        onRunFullTest: _runFullTestSuite,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
