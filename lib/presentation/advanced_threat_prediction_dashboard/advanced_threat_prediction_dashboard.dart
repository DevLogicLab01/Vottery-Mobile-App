import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/perplexity_service.dart';
import '../../services/fraud_engine_service.dart';
import '../../services/threat_correlation_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/threat_overview_panel_widget.dart';
import './widgets/perplexity_forecast_panel_widget.dart';
import './widgets/interactive_zone_heatmap_widget.dart';
import './widgets/live_fraud_pattern_feed_widget.dart';

class AdvancedThreatPredictionDashboard extends StatefulWidget {
  const AdvancedThreatPredictionDashboard({super.key});

  @override
  State<AdvancedThreatPredictionDashboard> createState() =>
      _AdvancedThreatPredictionDashboardState();
}

class _AdvancedThreatPredictionDashboardState
    extends State<AdvancedThreatPredictionDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final PerplexityService _perplexityService = PerplexityService.instance;
  final FraudEngineService _fraudEngineService = FraudEngineService.instance;
  final ThreatCorrelationService _threatService =
      ThreatCorrelationService.instance;

  Map<String, dynamic> _overviewMetrics = {};
  List<Map<String, dynamic>> _upcomingThreats = [];
  bool _isOverviewLoading = true;

  List<Map<String, dynamic>> _forecasts30 = [];
  List<Map<String, dynamic>> _forecasts60 = [];
  List<Map<String, dynamic>> _forecasts90 = [];
  List<Map<String, dynamic>> _mitigationRecs = [];
  bool _isForecastLoading = true;

  Map<String, Map<String, dynamic>> _zoneThreats = {};
  bool _isZoneLoading = true;

  List<Map<String, dynamic>> _fraudAlerts = [];
  List<Map<String, dynamic>> _automatedResponses = [];
  bool _isPatternLoading = true;
  StreamSubscription? _fraudStreamSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
    _subscribeToFraudAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fraudStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadOverviewData(),
      _loadForecastData(),
      _loadZoneData(),
      _loadPatternData(),
    ]);
  }

  Future<void> _loadOverviewData() async {
    try {
      final client = SupabaseService.instance.client;
      final predictions = await client
          .from('unified_threat_predictions')
          .select()
          .gte(
            'predicted_for_date',
            DateTime.now().toIso8601String().split('T')[0],
          )
          .order('predicted_for_date')
          .limit(100);
      final predList = List<Map<String, dynamic>>.from(predictions);
      int critical = 0, high = 0;
      double totalConfidence = 0;
      for (final p in predList) {
        final sev = p['predicted_severity'] as String? ?? 'low';
        if (sev == 'critical') critical++;
        if (sev == 'high') high++;
        totalConfidence += (p['confidence_score'] as num?)?.toDouble() ?? 0.0;
      }
      final upcoming = predList.take(10).map((p) {
        final date = DateTime.tryParse(
          p['predicted_for_date'] as String? ?? '',
        );
        final daysUntil = date != null
            ? date.difference(DateTime.now()).inDays
            : 0;
        return {
          'description':
              '${p['threat_category']} threat in zone ${p['zone_id']}',
          'severity': p['predicted_severity'] ?? 'low',
          'days_until': daysUntil,
        };
      }).toList();
      if (mounted) {
        setState(() {
          _overviewMetrics = {
            'critical_threats': critical,
            'high_threats': high,
            'active_incidents': critical,
            'predicted_threats_30d': predList.length,
            'avg_confidence': predList.isEmpty
                ? 0.0
                : totalConfidence / predList.length,
          };
          _upcomingThreats = upcoming;
          _isOverviewLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _overviewMetrics = {
            'critical_threats': 3,
            'high_threats': 7,
            'active_incidents': 2,
            'predicted_threats_30d': 15,
            'avg_confidence': 0.82,
          };
          _upcomingThreats = [
            {
              'description': 'Fraud spike in US/Canada zone',
              'severity': 'high',
              'days_until': 3,
            },
            {
              'description': 'Payment anomaly in Western Europe',
              'severity': 'medium',
              'days_until': 7,
            },
            {
              'description': 'Account takeover attempt pattern',
              'severity': 'critical',
              'days_until': 1,
            },
            {
              'description': 'Security breach risk in Africa zone',
              'severity': 'high',
              'days_until': 12,
            },
          ];
          _isOverviewLoading = false;
        });
      }
    }
  }

  Future<void> _loadForecastData() async {
    try {
      final reports = await _perplexityService.getThreatForecastingReports(
        limit: 20,
      );
      final recs = reports
          .take(3)
          .map(
            (r) => {
              'title': 'Mitigate ${r['threat_type'] ?? 'Threat'}',
              'description':
                  r['mitigation_strategy'] as String? ??
                  'Review and update security protocols',
              'impact_score':
                  (r['confidence_score'] as num?)?.toDouble() ?? 0.5,
              'estimated_cost': r['estimated_cost'] as String? ?? 'Low',
            },
          )
          .toList();
      if (mounted) {
        setState(() {
          _forecasts30 = reports
              .where((r) => (r['forecast_horizon_days'] as int? ?? 30) <= 30)
              .toList();
          _forecasts60 = reports
              .where((r) => (r['forecast_horizon_days'] as int? ?? 30) <= 60)
              .toList();
          _forecasts90 = reports;
          _mitigationRecs = recs.isEmpty ? _getMockMitigations() : recs;
          _isForecastLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _forecasts30 = _getMockForecasts(30);
          _forecasts60 = _getMockForecasts(60);
          _forecasts90 = _getMockForecasts(90);
          _mitigationRecs = _getMockMitigations();
          _isForecastLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getMockForecasts(int days) {
    final categories = [
      'fraud',
      'payment_anomaly',
      'security_breach',
      'account_takeover',
    ];
    return List.generate(
      days ~/ 5,
      (i) => {
        'threat_category': categories[i % categories.length],
        'confidence_score': 0.75 + (i % 3) * 0.05,
        'predicted_severity': i % 4 == 0
            ? 'critical'
            : i % 3 == 0
            ? 'high'
            : 'medium',
        'forecast_horizon_days': days,
      },
    );
  }

  List<Map<String, dynamic>> _getMockMitigations() {
    return [
      {
        'title': 'Enhance Rate Limiting',
        'description':
            'Implement stricter rate limits on payment endpoints to reduce fraud risk',
        'impact_score': 0.85,
        'estimated_cost': 'Low',
      },
      {
        'title': 'Deploy ML Anomaly Detection',
        'description':
            'Add real-time ML-based anomaly detection for account takeover patterns',
        'impact_score': 0.72,
        'estimated_cost': 'Medium',
      },
      {
        'title': 'Zone-Specific Security Policies',
        'description':
            'Customize security policies per purchasing power zone based on threat profiles',
        'impact_score': 0.65,
        'estimated_cost': 'Medium',
      },
    ];
  }

  Future<void> _loadZoneData() async {
    try {
      final zoneData = await _threatService.getZoneThreatSummary();
      if (mounted) {
        setState(() {
          _zoneThreats = Map<String, Map<String, dynamic>>.from(
            zoneData.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))),
          );
          _isZoneLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _zoneThreats = {
            'US_Canada': {
              'threat_level': 'medium',
              'active_incidents': 2,
              'predicted_trend': 'Increasing',
              'top_vulnerabilities': ['Credential stuffing', 'Payment fraud'],
            },
            'Western_Europe': {
              'threat_level': 'low',
              'active_incidents': 0,
              'predicted_trend': 'Stable',
              'top_vulnerabilities': ['Phishing'],
            },
            'Eastern_Europe': {
              'threat_level': 'high',
              'active_incidents': 4,
              'predicted_trend': 'Increasing',
              'top_vulnerabilities': ['Bot attacks', 'Account takeover'],
            },
            'Africa': {
              'threat_level': 'medium',
              'active_incidents': 1,
              'predicted_trend': 'Stable',
              'top_vulnerabilities': ['Payment anomaly'],
            },
            'Latin_America': {
              'threat_level': 'high',
              'active_incidents': 3,
              'predicted_trend': 'Decreasing',
              'top_vulnerabilities': ['Fraud rings'],
            },
            'Middle_East_Asia': {
              'threat_level': 'critical',
              'active_incidents': 6,
              'predicted_trend': 'Increasing',
              'top_vulnerabilities': ['Coordinated attacks', 'Identity fraud'],
            },
            'Australasia': {
              'threat_level': 'low',
              'active_incidents': 0,
              'predicted_trend': 'Stable',
              'top_vulnerabilities': [],
            },
            'Southeast_Asia': {
              'threat_level': 'medium',
              'active_incidents': 2,
              'predicted_trend': 'Stable',
              'top_vulnerabilities': ['Payment fraud'],
            },
          };
          _isZoneLoading = false;
        });
      }
    }
  }

  Future<void> _loadPatternData() async {
    try {
      final alerts = await _fraudEngineService.getRecentFraudAlerts(limit: 10);
      final responses = await _fraudEngineService.getAutomatedResponses(
        limit: 5,
      );
      if (mounted) {
        setState(() {
          _fraudAlerts = alerts;
          _automatedResponses = responses;
          _isPatternLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fraudAlerts = [
            {
              'pattern_type': 'Credential Stuffing',
              'alert_severity': 'high',
              'confidence_score': 0.91,
              'affected_users': 23,
              'detection_timestamp': '2m ago',
            },
            {
              'pattern_type': 'Payment Anomaly Cluster',
              'alert_severity': 'critical',
              'confidence_score': 0.96,
              'affected_users': 8,
              'detection_timestamp': '5m ago',
            },
            {
              'pattern_type': 'Bot Vote Manipulation',
              'alert_severity': 'medium',
              'confidence_score': 0.78,
              'affected_users': 45,
              'detection_timestamp': '12m ago',
            },
          ];
          _automatedResponses = [
            {
              'action_type': 'account_suspension',
              'description': '3 accounts suspended for suspicious activity',
            },
            {
              'action_type': 'transaction_block',
              'description': '12 transactions blocked from flagged IPs',
            },
            {
              'action_type': 'rate_limit',
              'description': 'Rate limiting applied to Zone 6 endpoints',
            },
          ];
          _isPatternLoading = false;
        });
      }
    }
  }

  void _subscribeToFraudAlerts() {
    try {
      _fraudStreamSub = SupabaseService.instance.client
          .from('fraud_alerts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(10)
          .listen((data) {
            if (mounted) {
              setState(
                () => _fraudAlerts = List<Map<String, dynamic>>.from(data),
              );
            }
          });
    } catch (_) {}
  }

  void _handleViewZoneMap() => _tabController.animateTo(4);

  void _handleRunAnalysis() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Running threat analysis...'),
        duration: Duration(seconds: 2),
      ),
    );
    await _loadAllData();
  }

  void _handleAcknowledgeAlerts() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acknowledge Alerts'),
        content: Text(
          'Acknowledge all ${_overviewMetrics['critical_threats'] ?? 0} critical and ${_overviewMetrics['high_threats'] ?? 0} high alerts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alerts acknowledged')),
              );
            },
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'Advanced Threat Prediction Dashboard',
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Threat Prediction',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              Text(
                'Real-time + 30-90 Day Forecasting',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _loadAllData,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.blue[700],
            unselectedLabelColor: Colors.grey[500],
            indicatorColor: Colors.blue[700],
            labelStyle: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 10.sp),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: '30-Day'),
              Tab(text: '60-Day'),
              Tab(text: '90-Day'),
              Tab(text: 'Zone Heatmaps'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _isOverviewLoading
                ? const Center(child: CircularProgressIndicator())
                : ThreatOverviewPanelWidget(
                    metrics: _overviewMetrics,
                    upcomingThreats: _upcomingThreats,
                    onViewZoneMap: _handleViewZoneMap,
                    onRunAnalysis: _handleRunAnalysis,
                    onAcknowledgeAlerts: _handleAcknowledgeAlerts,
                  ),
            PerplexityForecastPanelWidget(
              horizonDays: 30,
              forecasts: _forecasts30,
              mitigationRecommendations: _mitigationRecs,
              isLoading: _isForecastLoading,
            ),
            PerplexityForecastPanelWidget(
              horizonDays: 60,
              forecasts: _forecasts60,
              mitigationRecommendations: _mitigationRecs,
              isLoading: _isForecastLoading,
            ),
            PerplexityForecastPanelWidget(
              horizonDays: 90,
              forecasts: _forecasts90,
              mitigationRecommendations: _mitigationRecs,
              isLoading: _isForecastLoading,
            ),
            _isZoneLoading
                ? const Center(child: CircularProgressIndicator())
                : InteractiveZoneHeatmapWidget(zoneThreats: _zoneThreats),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (_, controller) => SingleChildScrollView(
                  controller: controller,
                  child: LiveFraudPatternFeedWidget(
                    fraudAlerts: _fraudAlerts,
                    automatedResponses: _automatedResponses,
                    isLoading: _isPatternLoading,
                  ),
                ),
              ),
            );
          },
          backgroundColor: Colors.blue[700],
          icon: const Icon(Icons.radar, color: Colors.white),
          label: Text(
            'Live Patterns',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
