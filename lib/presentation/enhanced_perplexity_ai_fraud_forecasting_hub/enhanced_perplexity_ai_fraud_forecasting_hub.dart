import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/advanced_perplexity_fraud_service.dart';
import '../../services/enhanced_analytics_service.dart';
import '../../services/perplexity_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/cross_platform_threat_correlation_widget.dart';
import './widgets/emerging_threat_identification_widget.dart';
import './widgets/forecast_confidence_header_widget.dart';
import './widgets/long_term_fraud_prediction_widget.dart';
import './widgets/seasonal_anomaly_charts_widget.dart';

class EnhancedPerplexityAiFraudForecastingHub extends StatefulWidget {
  const EnhancedPerplexityAiFraudForecastingHub({super.key});

  @override
  State<EnhancedPerplexityAiFraudForecastingHub> createState() =>
      _EnhancedPerplexityAiFraudForecastingHubState();
}

class _EnhancedPerplexityAiFraudForecastingHubState
    extends State<EnhancedPerplexityAiFraudForecastingHub>
    with SingleTickerProviderStateMixin {
  final PerplexityService _perplexityService = PerplexityService.instance;

  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic> _forecastData = {};
  double _confidenceScore = 0.0;
  String _threatLevel = 'low';
  double _modelAccuracy = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadForecastData();
    EnhancedAnalyticsService.instance.trackScreenView(
      screenName: 'Enhanced Perplexity AI Fraud Forecasting Hub',
      screenClass: 'EnhancedPerplexityAiFraudForecastingHub',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadForecastData() async {
    setState(() => _isLoading = true);
    try {
      final forecast = await _perplexityService.forecastFraudTrends(
        historicalData: [
          {'date': '2026-01-01', 'incidents': 45},
          {'date': '2026-01-15', 'incidents': 52},
          {'date': '2026-02-01', 'incidents': 38},
        ],
      );
      setState(() {
        _forecastData = forecast;
        _confidenceScore =
            (forecast['confidence_score'] as num?)?.toDouble() ?? 0.85;
        _threatLevel = forecast['threat_level']?.toString() ?? 'low';
        _modelAccuracy =
            (forecast['model_accuracy'] as num?)?.toDouble() ?? 0.92;
      });
    } catch (e) {
      debugPrint('Load forecast data error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedPerplexityAIFraudForecastingHub',
      onRetry: _loadForecastData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'AI Fraud Forecasting Hub',
            variant: CustomAppBarVariant.standard,
            actions: [
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: theme.appBarTheme.foregroundColor!,
                  size: 24,
                ),
                onPressed: _loadForecastData,
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  ForecastConfidenceHeaderWidget(
                    confidenceScore: _confidenceScore,
                    threatLevel: _threatLevel,
                    modelAccuracy: _modelAccuracy,
                  ),
                  Container(
                    color: theme.cardColor,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                      indicatorColor: theme.colorScheme.primary,
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: theme.textTheme.bodyMedium
                          ?.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                          ),
                      tabs: const [
                        Tab(text: 'Predictions'),
                        Tab(text: 'Threats'),
                        Tab(text: 'Seasonal'),
                        Tab(text: 'Correlation'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        LongTermFraudPredictionWidget(
                          forecastData: _forecastData,
                        ),
                        EmergingThreatIdentificationWidget(),
                        SeasonalAnomalyChartsWidget(),
                        CrossPlatformThreatCorrelationWidget(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
