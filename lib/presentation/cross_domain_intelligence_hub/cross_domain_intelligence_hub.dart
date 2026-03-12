import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/cross_domain_intelligence_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class CrossDomainIntelligenceHub extends StatefulWidget {
  const CrossDomainIntelligenceHub({super.key});

  @override
  State<CrossDomainIntelligenceHub> createState() =>
      _CrossDomainIntelligenceHubState();
}

class _CrossDomainIntelligenceHubState extends State<CrossDomainIntelligenceHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CrossDomainIntelligenceService _service =
      CrossDomainIntelligenceService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _intelligence = {};
  List<Map<String, dynamic>> _predictiveAlerts = [];
  List<Map<String, dynamic>> _correlations = [];
  Map<String, dynamic> _fraudPatterns = {};
  Map<String, dynamic> _engagementTrends = {};
  Map<String, dynamic> _monetizationMetrics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadIntelligenceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIntelligenceData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getCrossDomainIntelligence(timeWindowHours: 24),
        _service.getPredictiveAlerts(unresolvedOnly: true),
        _service.getMetricCorrelations(),
        _service.correlateFraudPatterns(),
        _service.analyzeEngagementTrends(),
        _service.analyzeMonetizationMetrics(),
      ]);

      setState(() {
        _intelligence = results[0] as Map<String, dynamic>;
        _predictiveAlerts = results[1] as List<Map<String, dynamic>>;
        _correlations = results[2] as List<Map<String, dynamic>>;
        _fraudPatterns = results[3] as Map<String, dynamic>;
        _engagementTrends = results[4] as Map<String, dynamic>;
        _monetizationMetrics = results[5] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CrossDomainIntelligenceHub',
      onRetry: _loadIntelligenceData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Cross-Domain Intelligence',
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryLight),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: AppTheme.primaryLight),
              onPressed: _loadIntelligenceData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPredictiveAlertsTab(),
                          _buildCorrelationHeatmapTab(),
                          _buildMultiAIConsensusTab(),
                          _buildInsightsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
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
        labelStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(text: 'Alerts'),
          Tab(text: 'Correlations'),
          Tab(text: 'AI Consensus'),
          Tab(text: 'Insights'),
        ],
      ),
    );
  }

  Widget _buildPredictiveAlertsTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Predictive Alerts',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        if (_predictiveAlerts.isEmpty)
          _buildEmptyState('No active alerts')
        else
          ..._predictiveAlerts.map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final alertType = alert['alert_type'] ?? 'unknown';
    final severity = alert['alert_severity'] ?? 'low';
    final predictedEvent = alert['predicted_event'] ?? '';
    final confidence =
        (alert['confidence_interval'] as num?)?.toDouble() ?? 0.0;
    final consensusScore =
        (alert['ai_consensus_score'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _getSeverityColor(severity)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  alertType.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            predictedEvent,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildMetricChip(
                'Confidence',
                '${(confidence * 100).toStringAsFixed(0)}%',
              ),
              SizedBox(width: 2.w),
              _buildMetricChip(
                'AI Consensus',
                '${(consensusScore * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _acknowledgeAlert(alert['id']),
                  child: Text(
                    'Acknowledge',
                    style: GoogleFonts.inter(fontSize: 11.sp),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _resolveAlert(alert['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                  ),
                  child: Text(
                    'Resolve',
                    style: GoogleFonts.inter(fontSize: 11.sp),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationHeatmapTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Metric Correlations',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        if (_correlations.isEmpty)
          _buildEmptyState('No correlations found')
        else
          ..._correlations.take(10).map((corr) => _buildCorrelationCard(corr)),
      ],
    );
  }

  Widget _buildCorrelationCard(Map<String, dynamic> correlation) {
    final metricA = correlation['metric_a'] ?? '';
    final metricB = correlation['metric_b'] ?? '';
    final coefficient =
        (correlation['correlation_coefficient'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metricA.replaceAll('_', ' '),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Icon(
                Icons.compare_arrows,
                size: 5.w,
                color: AppTheme.primaryLight,
              ),
              Expanded(
                child: Text(
                  metricB.replaceAll('_', ' '),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: (coefficient.abs() / 1.0).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              coefficient > 0 ? Colors.green : Colors.red,
            ),
            minHeight: 1.h,
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Correlation: ${coefficient.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: coefficient > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiAIConsensusTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Multi-AI Consensus',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        _buildConsensusPanel(),
      ],
    );
  }

  Widget _buildConsensusPanel() {
    final fraudConsensus = _fraudPatterns['consensus_score'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fraud Detection Consensus',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildAIServiceCard('Perplexity', fraudConsensus, Colors.purple),
          SizedBox(height: 1.h),
          _buildAIServiceCard('Claude', fraudConsensus, Colors.orange),
          SizedBox(height: 1.h),
          _buildAIServiceCard('OpenAI', fraudConsensus, Colors.green),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Consensus',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  '${(fraudConsensus * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIServiceCard(String service, double score, Color color) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(Icons.check, color: Colors.white, size: 4.w),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(height: 0.5.h),
              LinearProgressIndicator(
                value: score,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 0.8.h,
              ),
            ],
          ),
        ),
        SizedBox(width: 3.w),
        Text(
          '${(score * 100).toStringAsFixed(0)}%',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'AI-Generated Insights',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        _buildInsightCard(
          'Fraud Patterns',
          'Multi-AI analysis detected ${_fraudPatterns['claude_disputes']?['count'] ?? 0} high-severity fraud patterns',
          Icons.security,
          Colors.red,
        ),
        _buildInsightCard(
          'Engagement Trends',
          'Vote-comment correlation: ${(_engagementTrends['vote_comment_correlation'] ?? 0.0).toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.blue,
        ),
        _buildInsightCard(
          'Monetization',
          'Total revenue: \$${(_monetizationMetrics['total_revenue'] ?? 0.0).toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String title,
    String insight,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  insight,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
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

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryLight,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    await _service.acknowledgePredictiveAlert(alertId);
    _loadIntelligenceData();
  }

  Future<void> _resolveAlert(String alertId) async {
    await _service.resolvePredictiveAlert(
      alertId: alertId,
      resolutionNotes: 'Resolved from mobile app',
    );
    _loadIntelligenceData();
  }
}
