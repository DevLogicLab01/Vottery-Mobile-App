import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/enhanced_analytics_cdn_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/cdn_performance_dashboard_widget.dart';
import './widgets/predictive_analytics_engine_widget.dart';
import './widgets/engagement_forecasting_widget.dart';
import './widgets/anomaly_detection_widget.dart';
import './widgets/cdn_controls_widget.dart';
import './widgets/trend_visualization_widget.dart';

/// Enhanced Analytics with CDN Integration Hub
/// Combines Cloudflare CDN optimization with OpenAI-powered predictive analytics
class EnhancedAnalyticsWithCdnIntegrationHub extends StatefulWidget {
  const EnhancedAnalyticsWithCdnIntegrationHub({super.key});

  @override
  State<EnhancedAnalyticsWithCdnIntegrationHub> createState() =>
      _EnhancedAnalyticsWithCdnIntegrationHubState();
}

class _EnhancedAnalyticsWithCdnIntegrationHubState
    extends State<EnhancedAnalyticsWithCdnIntegrationHub>
    with SingleTickerProviderStateMixin {
  final EnhancedAnalyticsCDNService _analyticsService =
      EnhancedAnalyticsCDNService.instance;

  late TabController _tabController;
  Map<String, dynamic> _cdnMetrics = {};
  Map<String, dynamic>? _predictiveAnalytics;
  List<Map<String, dynamic>> _anomalies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final cdnMetrics = await _analyticsService.getCDNPerformanceMetrics();
    final predictive = await _analyticsService.getPredictiveAnalytics(
      metricType: 'user_growth',
      forecastDays: 30,
    );
    final anomalies = await _analyticsService.detectAnomalies('user_growth');

    if (mounted) {
      setState(() {
        _cdnMetrics = cdnMetrics;
        _predictiveAnalytics = predictive;
        _anomalies = anomalies;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedAnalyticsWithCdnIntegrationHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Enhanced Analytics Hub',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: theme.colorScheme.primary,
                child: Column(
                  children: [
                    // Analytics Overview Header
                    _buildAnalyticsHeader(theme),

                    SizedBox(height: 2.h),

                    // Tab Bar
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.onPrimary,
                        unselectedLabelColor:
                            theme.colorScheme.onSurfaceVariant,
                        indicator: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tabs: const [
                          Tab(text: 'CDN'),
                          Tab(text: 'Predictions'),
                          Tab(text: 'Forecasting'),
                          Tab(text: 'Anomalies'),
                        ],
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // CDN Performance Dashboard
                          SingleChildScrollView(
                            padding: EdgeInsets.all(4.w),
                            child: Column(
                              children: [
                                CDNPerformanceDashboardWidget(
                                  metrics: _cdnMetrics,
                                ),
                                SizedBox(height: 2.h),
                                CDNControlsWidget(
                                  onOptimize: _handleOptimization,
                                ),
                              ],
                            ),
                          ),

                          // Predictive Analytics Engine
                          SingleChildScrollView(
                            padding: EdgeInsets.all(4.w),
                            child: Column(
                              children: [
                                PredictiveAnalyticsEngineWidget(
                                  analytics: _predictiveAnalytics,
                                ),
                                SizedBox(height: 2.h),
                                TrendVisualizationWidget(
                                  predictions:
                                      _predictiveAnalytics?['predictions'] ??
                                      [],
                                ),
                              ],
                            ),
                          ),

                          // Engagement Forecasting
                          SingleChildScrollView(
                            padding: EdgeInsets.all(4.w),
                            child: EngagementForecastingWidget(
                              analytics: _predictiveAnalytics,
                            ),
                          ),

                          // Anomaly Detection
                          SingleChildScrollView(
                            padding: EdgeInsets.all(4.w),
                            child: AnomalyDetectionWidget(
                              anomalies: _anomalies,
                              onRefresh: _loadData,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAnalyticsHeader(ThemeData theme) {
    final cacheHitRatio = _cdnMetrics['cache_hit_ratio'] ?? 0.0;
    final edgeLocations = _cdnMetrics['edge_locations'] ?? 0;
    final predictiveConfidence =
        _predictiveAnalytics?['confidence_intervals']?['upper'] ?? 0.0;

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: theme.colorScheme.onPrimary,
                size: 32,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics Overview',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'CDN + AI-Powered Predictions',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Cache Hit Ratio',
                  '${cacheHitRatio.toStringAsFixed(1)}%',
                  Icons.speed,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Edge Locations',
                  edgeLocations.toString(),
                  Icons.public,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'AI Confidence',
                  '${(predictiveConfidence * 100).toStringAsFixed(0)}%',
                  Icons.psychology,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.onPrimary, size: 20),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _handleOptimization(String type) async {
    // Handle CDN optimization actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Optimizing $type...'),
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    await _loadData();
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 2.h),
        child: SkeletonCard(height: 150, width: double.infinity),
      ),
    );
  }
}
