import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/predictive_analytics_service.dart';
import './widgets/forecast_overview_cards_widget.dart';
import './widgets/traffic_forecast_detail_widget.dart';
import './widgets/fraud_forecast_detail_widget.dart';
import './widgets/infrastructure_forecast_detail_widget.dart';
import './widgets/recommendations_panel_widget.dart';

class AiPoweredPredictiveAnalyticsEngine extends StatefulWidget {
  const AiPoweredPredictiveAnalyticsEngine({super.key});

  @override
  State<AiPoweredPredictiveAnalyticsEngine> createState() =>
      _AiPoweredPredictiveAnalyticsEngineState();
}

class _AiPoweredPredictiveAnalyticsEngineState
    extends State<AiPoweredPredictiveAnalyticsEngine> {
  final PredictiveAnalyticsService _service =
      PredictiveAnalyticsService.instance;

  Map<String, dynamic> _trafficForecast = {};
  Map<String, dynamic> _fraudForecast = {};
  Map<String, dynamic> _infrastructureForecast = {};
  List<Map<String, dynamic>> _recommendations = [];

  bool _isLoading = true;
  bool _isGenerating = false;
  String _selectedView = 'overview';
  DateTime? _lastForecastUpdate;

  @override
  void initState() {
    super.initState();
    _loadForecasts();
  }

  Future<void> _loadForecasts() async {
    setState(() => _isLoading = true);

    try {
      // Load existing forecasts or generate new ones
      await _generateForecasts();
    } catch (e) {
      debugPrint('Load forecasts error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateForecasts() async {
    setState(() => _isGenerating = true);

    try {
      // Generate forecasts in parallel
      final results = await Future.wait([
        _service.forecastTrafficPatterns(),
        _service.forecastFraudTrends(),
      ]);

      final trafficForecast = results[0];
      final fraudForecast = results[1];

      // Generate infrastructure forecast based on traffic
      final infrastructureForecast = await _service
          .forecastInfrastructureScaling(trafficForecast);

      // Generate recommendations
      final recommendations = await _service.generateActionableRecommendations(
        trafficForecast: trafficForecast,
        fraudForecast: fraudForecast,
        infrastructureForecast: infrastructureForecast,
      );

      setState(() {
        _trafficForecast = trafficForecast;
        _fraudForecast = fraudForecast;
        _infrastructureForecast = infrastructureForecast;
        _recommendations = recommendations;
        _lastForecastUpdate = DateTime.now();
      });
    } catch (e) {
      debugPrint('Generate forecasts error: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('AI-Powered Predictive Analytics'),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        actions: [
          if (_lastForecastUpdate != null)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Text(
                  'Updated ${_formatTimestamp(_lastForecastUpdate!)}',
                  style: TextStyle(fontSize: 11.sp),
                ),
              ),
            ),
          IconButton(
            icon: _isGenerating
                ? SizedBox(
                    width: 20.sp,
                    height: 20.sp,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isGenerating ? null : _generateForecasts,
            tooltip: 'Refresh Forecasts',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadForecasts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildViewSelector(),
                    SizedBox(height: 3.h),
                    if (_selectedView == 'overview') ..._buildOverviewView(),
                    if (_selectedView == 'traffic') ..._buildTrafficView(),
                    if (_selectedView == 'fraud') ..._buildFraudView(),
                    if (_selectedView == 'infrastructure')
                      ..._buildInfrastructureView(),
                    if (_selectedView == 'recommendations')
                      ..._buildRecommendationsView(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildViewSelector() {
    final views = [
      {'id': 'overview', 'label': 'Overview', 'icon': Icons.dashboard},
      {'id': 'traffic', 'label': 'Traffic', 'icon': Icons.trending_up},
      {'id': 'fraud', 'label': 'Fraud', 'icon': Icons.security},
      {
        'id': 'infrastructure',
        'label': 'Infrastructure',
        'icon': Icons.storage,
      },
      {'id': 'recommendations', 'label': 'Actions', 'icon': Icons.lightbulb},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: views.map((view) {
          final isSelected = _selectedView == view['id'];
          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    view['icon'] as IconData,
                    size: 16.sp,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  SizedBox(width: 1.w),
                  Text(view['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedView = view['id'] as String);
                }
              },
              selectedColor: Colors.deepPurple[700],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12.sp,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildOverviewView() {
    return [
      ForecastOverviewCardsWidget(
        trafficForecast: _trafficForecast,
        fraudForecast: _fraudForecast,
        infrastructureForecast: _infrastructureForecast,
        onViewDetails: (type) {
          setState(() => _selectedView = type);
        },
      ),
      SizedBox(height: 3.h),
      Text(
        'Top Recommendations',
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 2.h),
      ..._recommendations.take(3).map((rec) => _buildRecommendationCard(rec)),
    ];
  }

  List<Widget> _buildTrafficView() {
    return [TrafficForecastDetailWidget(forecast: _trafficForecast)];
  }

  List<Widget> _buildFraudView() {
    return [FraudForecastDetailWidget(forecast: _fraudForecast)];
  }

  List<Widget> _buildInfrastructureView() {
    return [
      InfrastructureForecastDetailWidget(forecast: _infrastructureForecast),
    ];
  }

  List<Widget> _buildRecommendationsView() {
    return [
      RecommendationsPanelWidget(
        recommendations: _recommendations,
        onStatusUpdate: (recId, status) async {
          await _service.updateRecommendationStatus(
            recommendationId: recId,
            status: status,
          );
          await _loadForecasts();
        },
      ),
    ];
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final priority = recommendation['priority'] as String;
    Color priorityColor;
    switch (priority) {
      case 'critical':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'medium':
        priorityColor = Colors.blue;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: priorityColor.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
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
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  recommendation['recommendation'] ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Category: ${recommendation['category']}',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          Text(
            'Est. Time: ${recommendation['estimated_implementation_time']}',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
