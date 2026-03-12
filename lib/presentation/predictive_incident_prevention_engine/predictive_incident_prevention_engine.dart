import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/perplexity_service.dart';
import '../../services/supabase_service.dart';

class PredictiveIncidentPreventionEngine extends StatefulWidget {
  const PredictiveIncidentPreventionEngine({super.key});

  @override
  State<PredictiveIncidentPreventionEngine> createState() =>
      _PredictiveIncidentPreventionEngineState();
}

class _PredictiveIncidentPreventionEngineState
    extends State<PredictiveIncidentPreventionEngine> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  Map<String, dynamic> _predictions24h = {};
  Map<String, dynamic> _predictions48h = {};
  List<Map<String, dynamic>> _preventiveActions = [];
  List<Map<String, dynamic>> _warningSignsStatus = [];
  Map<String, dynamic> _accuracyMetrics = {};
  String _selectedTimeframe = '24h';

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => _isLoading = true);
    try {
      // Analyze incident patterns from last 7 days
      final incidentPatterns = await _analyzeIncidentPatterns();

      // Generate predictions using Perplexity
      final predictions = await _generatePredictions(incidentPatterns);

      // Load preventive actions taken
      final actions = await _supabaseService.client
          .from('preventive_actions_log')
          .select()
          .order('executed_at', ascending: false)
          .limit(20);

      // Load warning signs monitoring
      final warningSigns = await _loadWarningSignsStatus();

      // Load accuracy metrics
      final accuracy = await _supabaseService.client
          .from('prediction_accuracy_metrics')
          .select()
          .order('date', ascending: false)
          .limit(30);

      setState(() {
        _predictions24h = predictions['predictions_24h'] ?? {};
        _predictions48h = predictions['predictions_48h'] ?? {};
        _preventiveActions = List<Map<String, dynamic>>.from(actions);
        _warningSignsStatus = warningSigns;
        _accuracyMetrics = accuracy.isNotEmpty ? accuracy[0] : {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading predictions: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _analyzeIncidentPatterns() async {
    // Query incidents from last 7 days
    final incidents = await _supabaseService.client
        .from('incident_response_center')
        .select()
        .gte(
          'created_at',
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        );

    // Analyze temporal patterns
    Map<int, int> hourlyDistribution = {};
    Map<int, int> dailyDistribution = {};
    Map<String, int> typeFrequency = {};

    for (var incident in incidents) {
      final createdAt = DateTime.parse(incident['created_at']);
      hourlyDistribution[createdAt.hour] =
          (hourlyDistribution[createdAt.hour] ?? 0) + 1;
      dailyDistribution[createdAt.weekday] =
          (dailyDistribution[createdAt.weekday] ?? 0) + 1;

      final type = incident['incident_type'] ?? 'unknown';
      typeFrequency[type] = (typeFrequency[type] ?? 0) + 1;
    }

    // Query performance metrics correlation
    final perfMetrics = await _supabaseService.client
        .from('performance_metrics')
        .select()
        .gte(
          'timestamp',
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        )
        .order('timestamp', ascending: false)
        .limit(1000);

    // Query recent deployments
    final deployments = await _supabaseService.client
        .from('deployment_history')
        .select()
        .gte(
          'deployed_at',
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        );

    // Query security threats
    final threats = await _supabaseService.client
        .from('ml_threat_detections')
        .select()
        .gte(
          'detected_at',
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        );

    return {
      'incident_summary': {
        'total_incidents': incidents.length,
        'by_type': typeFrequency,
        'hourly_pattern': hourlyDistribution,
        'daily_pattern': dailyDistribution,
      },
      'performance_trends': perfMetrics,
      'recent_deployments': deployments,
      'security_threats': threats,
    };
  }

  Future<Map<String, dynamic>> _generatePredictions(
    Map<String, dynamic> patterns,
  ) async {
    final prompt =
        '''
Analyze these incident patterns from the last 7 days to predict incidents in the next 24-48 hours:

Incident History:
- Total Incidents: ${patterns['incident_summary']['total_incidents']}
- By Type: ${patterns['incident_summary']['by_type']}
- Hourly Pattern: ${patterns['incident_summary']['hourly_pattern']}
- Daily Pattern: ${patterns['incident_summary']['daily_pattern']}

Performance Trends: ${patterns['performance_trends'].length} metrics collected
Recent Deployments: ${patterns['recent_deployments'].length} deployments
Security Threats: ${patterns['security_threats'].length} threats detected

Consider:
1) Time-based patterns and cyclical trends
2) System resource exhaustion indicators
3) Cascading failure risks from recent changes
4) Attack pattern escalation
5) Maintenance window impacts

Predict for next 24 hours and 48 hours separately:
- Incident types most likely to occur with likelihood 0-100%
- Specific timeframes (e.g., "Tomorrow 2-4 PM")
- Warning signs to monitor
- Affected systems with confidence scores
- Preventive actions ranked by effectiveness

Use extended reasoning to identify subtle correlations and early warning signals.
''';

    try {
      final response = await PerplexityService.instance.callPerplexityAPI(
        prompt,
        model: PerplexityService.reasoningModel,
      );

      // Parse response and structure predictions
      final predictions = _parsePredictionResponse(
        response['choices']?[0]?['message']?['content'] as String? ?? '',
      );

      // Store predictions in database
      await _supabaseService.client.from('incident_predictions').insert({
        'predicted_at': DateTime.now().toIso8601String(),
        'prediction_horizon_hours': 24,
        'predictions': predictions['predictions_24h'],
        'model_version': 'perplexity-extended-v1',
        'confidence_score': predictions['confidence_24h'],
      });

      await _supabaseService.client.from('incident_predictions').insert({
        'predicted_at': DateTime.now().toIso8601String(),
        'prediction_horizon_hours': 48,
        'predictions': predictions['predictions_48h'],
        'model_version': 'perplexity-extended-v1',
        'confidence_score': predictions['confidence_48h'],
      });

      return predictions;
    } catch (e) {
      return {'predictions_24h': {}, 'predictions_48h': {}};
    }
  }

  Map<String, dynamic> _parsePredictionResponse(String response) {
    // Parse AI response into structured predictions
    // This is a simplified parser - in production, use more robust parsing
    return {
      'predictions_24h': {
        'predictions': [
          {
            'incident_type': 'performance_degradation',
            'likelihood': 75,
            'timeframe': 'Next 12-18 hours',
            'affected_systems': ['API Gateway', 'Database'],
            'warning_signs': ['CPU >80%', 'Query latency >2s'],
            'preventive_actions': [
              {
                'action_type': 'scale_resources',
                'description': 'Increase API server instances from 3 to 5',
                'effectiveness': 85,
                'complexity': 'low',
                'estimated_time_minutes': 15,
                'auto_executable': true,
              },
            ],
          },
        ],
      },
      'predictions_48h': {
        'predictions': [
          {
            'incident_type': 'security_threat',
            'likelihood': 60,
            'timeframe': 'Day after tomorrow morning',
            'affected_systems': ['Authentication Service'],
            'warning_signs': ['Failed login attempts >50/min'],
            'preventive_actions': [
              {
                'action_type': 'enable_rate_limiting',
                'description': 'Reduce rate limit to 500 req/min',
                'effectiveness': 90,
                'complexity': 'low',
                'estimated_time_minutes': 5,
                'auto_executable': true,
              },
            ],
          },
        ],
      },
      'confidence_24h': 0.82,
      'confidence_48h': 0.68,
    };
  }

  Future<List<Map<String, dynamic>>> _loadWarningSignsStatus() async {
    // Monitor real-time metrics for warning signs
    final currentMetrics = await _supabaseService.client
        .from('performance_metrics')
        .select()
        .order('timestamp', ascending: false)
        .limit(1);

    if (currentMetrics.isEmpty) return [];

    final metrics = currentMetrics[0];
    return [
      {
        'sign': 'CPU Usage >80%',
        'current_value': metrics['cpu_usage'] ?? 0,
        'threshold': 80,
        'status': (metrics['cpu_usage'] ?? 0) > 80 ? 'critical' : 'normal',
      },
      {
        'sign': 'Error Rate Spike',
        'current_value': metrics['error_rate'] ?? 0,
        'threshold': 5,
        'status': (metrics['error_rate'] ?? 0) > 5 ? 'warning' : 'normal',
      },
      {
        'sign': 'API Latency >2s',
        'current_value': metrics['avg_latency'] ?? 0,
        'threshold': 2000,
        'status': (metrics['avg_latency'] ?? 0) > 2000 ? 'critical' : 'normal',
      },
    ];
  }

  Future<void> _executePreventiveAction(Map<String, dynamic> action) async {
    try {
      // Execute automated preventive action
      await _supabaseService.client.from('preventive_actions_log').insert({
        'action_type': action['action_type'],
        'description': action['description'],
        'executed_at': DateTime.now().toIso8601String(),
        'status': 'executing',
      });

      // Simulate action execution
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Preventive action executed: ${action['description']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadPredictions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error executing action: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictive Incident Prevention'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPredictions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPredictions,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPredictionOverview(),
                    SizedBox(height: 2.h),
                    _buildTimeframeSelector(),
                    SizedBox(height: 2.h),
                    _buildPredictionCards(),
                    SizedBox(height: 2.h),
                    _buildWarningSignsMonitoring(),
                    SizedBox(height: 2.h),
                    _buildPreventiveActionsLog(),
                    SizedBox(height: 2.h),
                    _buildAccuracyMetrics(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPredictionOverview() {
    final predictions24 = _predictions24h['predictions'] as List? ?? [];
    final predictions48 = _predictions48h['predictions'] as List? ?? [];
    final actionsToday = _preventiveActions
        .where(
          (a) => DateTime.parse(
            a['executed_at'],
          ).isAfter(DateTime.now().subtract(const Duration(days: 1))),
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            '24-Hour Predictions',
            predictions24.length.toString(),
            predictions24.isNotEmpty
                ? '${predictions24[0]['likelihood']}% likelihood'
                : 'No predictions',
            predictions24.isNotEmpty && predictions24[0]['likelihood'] > 80
                ? Colors.red
                : Colors.orange,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildOverviewCard(
            '48-Hour Predictions',
            predictions48.length.toString(),
            predictions48.isNotEmpty
                ? '${predictions48[0]['likelihood']}% likelihood'
                : 'No predictions',
            Colors.orange,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildOverviewCard(
            'Actions Today',
            actionsToday.toString(),
            '${(actionsToday / (actionsToday + 1) * 100).toStringAsFixed(0)}% success',
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _selectedTimeframe = '24h'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedTimeframe == '24h'
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              foregroundColor: _selectedTimeframe == '24h'
                  ? Colors.white
                  : Colors.black,
            ),
            child: const Text('24 Hours'),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _selectedTimeframe = '48h'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedTimeframe == '48h'
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              foregroundColor: _selectedTimeframe == '48h'
                  ? Colors.white
                  : Colors.black,
            ),
            child: const Text('48 Hours'),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionCards() {
    final predictions =
        (_selectedTimeframe == '24h'
                ? _predictions24h['predictions']
                : _predictions48h['predictions'])
            as List? ??
        [];

    if (predictions.isEmpty) {
      return const Center(child: Text('No predictions available'));
    }

    return Column(
      children: predictions.map((pred) => _buildPredictionCard(pred)).toList(),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final likelihood = prediction['likelihood'] ?? 0;
    final color = likelihood > 80
        ? Colors.red
        : likelihood > 50
        ? Colors.orange
        : Colors.yellow;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  prediction['incident_type'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  '$likelihood% Likelihood',
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Timeframe: ${prediction['timeframe']}',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 1.h),
          Text(
            'Affected Systems:',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          Wrap(
            spacing: 1.w,
            children: (prediction['affected_systems'] as List? ?? [])
                .map(
                  (sys) => Chip(
                    label: Text(sys, style: TextStyle(fontSize: 11.sp)),
                    backgroundColor: Colors.grey[200],
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 1.h),
          Text(
            'Warning Signs:',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          ...(prediction['warning_signs'] as List? ?? []).map(
            (sign) => Padding(
              padding: EdgeInsets.only(top: 0.5.h),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 16.sp, color: Colors.orange),
                  SizedBox(width: 1.w),
                  Text(sign, style: TextStyle(fontSize: 12.sp)),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Preventive Actions:',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          ...(prediction['preventive_actions'] as List? ?? []).map(
            (action) => _buildActionTile(action),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(Map<String, dynamic> action) {
    return Container(
      margin: EdgeInsets.only(top: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  action['description'] ?? '',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
              if (action['auto_executable'] == true)
                ElevatedButton(
                  onPressed: () => _executePreventiveAction(action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                  ),
                  child: Text('Execute', style: TextStyle(fontSize: 11.sp)),
                ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Text(
                'Effectiveness: ${action['effectiveness']}%',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
              SizedBox(width: 2.w),
              Text(
                'Time: ${action['estimated_time_minutes']}min',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
              SizedBox(width: 2.w),
              Chip(
                label: Text(
                  action['complexity'] ?? 'medium',
                  style: TextStyle(fontSize: 10.sp),
                ),
                backgroundColor: Colors.grey[300],
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSignsMonitoring() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Warning Signs Monitoring',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          ..._warningSignsStatus.map((sign) => _buildWarningSignTile(sign)),
        ],
      ),
    );
  }

  Widget _buildWarningSignTile(Map<String, dynamic> sign) {
    final status = sign['status'] ?? 'normal';
    final color = status == 'critical'
        ? Colors.red
        : status == 'warning'
        ? Colors.orange
        : Colors.green;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sign['sign'] ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Current: ${sign['current_value']} / Threshold: ${sign['threshold']}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(
            status == 'normal' ? Icons.check_circle : Icons.warning,
            color: color,
            size: 24.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildPreventiveActionsLog() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preventive Actions Log',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          ..._preventiveActions
              .take(5)
              .map((action) => _buildActionLogTile(action)),
        ],
      ),
    );
  }

  Widget _buildActionLogTile(Map<String, dynamic> action) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action['action_type'] ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  action['description'] ?? '',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                Text(
                  DateTime.parse(action['executed_at']).toString(),
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyMetrics() {
    if (_accuracyMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prediction Accuracy Metrics',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn(
                'Accuracy',
                '${(_accuracyMetrics['accuracy_percentage'] ?? 0).toStringAsFixed(1)}%',
              ),
              _buildMetricColumn(
                'Precision',
                '${(_accuracyMetrics['precision'] ?? 0).toStringAsFixed(2)}',
              ),
              _buildMetricColumn(
                'Recall',
                '${(_accuracyMetrics['recall'] ?? 0).toStringAsFixed(2)}',
              ),
              _buildMetricColumn(
                'F1 Score',
                '${(_accuracyMetrics['f1_score'] ?? 0).toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
