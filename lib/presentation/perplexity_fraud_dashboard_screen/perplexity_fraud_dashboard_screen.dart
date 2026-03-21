import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/advanced_perplexity_fraud_service.dart';
import '../../services/perplexity_fraud_analyzer_service.dart';
import '../../services/platform_log_aggregator_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class PerplexityFraudDashboardScreen extends StatefulWidget {
  const PerplexityFraudDashboardScreen({super.key});

  @override
  State<PerplexityFraudDashboardScreen> createState() =>
      _PerplexityFraudDashboardScreenState();
}

class _PerplexityFraudDashboardScreenState
    extends State<PerplexityFraudDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _fraudAnalyzer = PerplexityFraudAnalyzerService();
  final _logAggregator = PlatformLogAggregatorService();

  late TabController _tabController;
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String? _error;

  // Dashboard data
  int _activeThreats = 0;
  int _predictedThreats24h = 0;
  int _analyzedLogsToday = 0;
  double _analysisConfidence = 0.0;

  List<Map<String, dynamic>> _detectedPatterns = [];
  List<Map<String, dynamic>> _threatPredictions = [];
  List<Map<String, dynamic>> _recentAnalyses = [];
  List<Map<String, dynamic>> _searchResults = [];

  final _searchController = TextEditingController();
  String _selectedEventType = 'all';
  String _selectedSeverity = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
    _startLogAggregation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _logAggregator.stopAggregation();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load summary statistics
      await _loadSummaryStats();

      await _loadSupabaseFraudSignals();

      // Load detected patterns
      await _loadDetectedPatterns();

      // Load threat predictions
      await _loadThreatPredictions();

      // Load recent analyses
      await _loadRecentAnalyses();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSummaryStats() async {
    // Active threats (high-severity patterns from last 24 hours)
    final patternsResponse = await _supabase
        .from('fraud_analysis_results')
        .select('detected_patterns')
        .gte(
          'analysis_timestamp',
          DateTime.now().subtract(Duration(hours: 24)).toIso8601String(),
        )
        .order('analysis_timestamp', ascending: false)
        .limit(10);

    var activeCount = 0;
    for (final result in patternsResponse as List) {
      final patterns = result['detected_patterns'] as List? ?? [];
      activeCount += patterns
          .where((p) => p['severity'] == 'critical' || p['severity'] == 'high')
          .length;
    }

    // Predicted threats (next 24 hours)
    final predictionsResponse = await _supabase
        .from('threat_predictions')
        .select()
        .eq('status', 'active')
        .gte('likelihood_percentage', 60)
        .order('likelihood_percentage', ascending: false);

    // Analyzed logs today
    final logsResponse = await _supabase
        .from('fraud_analysis_results')
        .select('analyzed_log_count')
        .gte(
          'analysis_timestamp',
          DateTime.now().subtract(Duration(hours: 24)).toIso8601String(),
        );

    var totalLogs = 0;
    var totalConfidence = 0.0;
    var confidenceCount = 0;

    for (final result in logsResponse as List) {
      totalLogs += result['analyzed_log_count'] as int? ?? 0;
      final confidence = result['confidence_score'] as num?;
      if (confidence != null) {
        totalConfidence += confidence.toDouble();
        confidenceCount++;
      }
    }

    setState(() {
      _activeThreats = activeCount;
      _predictedThreats24h = (predictionsResponse as List).length;
      _analyzedLogsToday = totalLogs;
      _analysisConfidence = confidenceCount > 0
          ? totalConfidence / confidenceCount
          : 0.0;
    });
  }

  Future<void> _loadDetectedPatterns() async {
    final response = await _supabase
        .from('fraud_analysis_results')
        .select(
          'analysis_id, analysis_timestamp, detected_patterns, confidence_score',
        )
        .order('analysis_timestamp', ascending: false)
        .limit(20);

    final patterns = <Map<String, dynamic>>[];
    for (final result in response as List) {
      final detectedPatterns = result['detected_patterns'] as List? ?? [];
      for (final pattern in detectedPatterns) {
        patterns.add({
          ...pattern,
          'analysis_id': result['analysis_id'],
          'analysis_timestamp': result['analysis_timestamp'],
          'overall_confidence': result['confidence_score'],
        });
      }
    }

    setState(() {
      _detectedPatterns = patterns;
    });
  }

  Future<void> _loadThreatPredictions() async {
    final response = await _supabase
        .from('threat_predictions')
        .select()
        .eq('status', 'active')
        .order('likelihood_percentage', ascending: false)
        .limit(20);

    setState(() {
      _threatPredictions = (response as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> _loadRecentAnalyses() async {
    final response = await _supabase
        .from('fraud_analysis_results')
        .select()
        .order('analysis_timestamp', ascending: false)
        .limit(10);

    setState(() {
      _recentAnalyses = (response as List).cast<Map<String, dynamic>>();
    });
  }

  void _startLogAggregation() {
    _logAggregator.startAggregation();
  }

  Future<void> _triggerManualAnalysis() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Trigger manual log aggregation
      await _logAggregator.triggerManualAggregation();

      // Run fraud analysis
      final result = await _fraudAnalyzer.analyzeLogs();

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Analysis completed: ${result['patterns_detected']} patterns detected',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reload dashboard data
        await _loadDashboardData();
      } else {
        throw Exception(result['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _searchLogs() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      var queryBuilder = _supabase
          .from('platform_logs_aggregated')
          .select()
          .or('action.ilike.%$query%,resource.ilike.%$query%');

      if (_selectedEventType != 'all') {
        queryBuilder = queryBuilder.eq('event_type', _selectedEventType);
      }

      if (_selectedSeverity != 'all') {
        queryBuilder = queryBuilder.eq('severity', _selectedSeverity);
      }

      final response = await queryBuilder
          .order('timestamp', ascending: false)
          .limit(100);

      setState(() {
        _searchResults = (response as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perplexity Fraud Analysis',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        actions: [
          IconButton(
            icon: _isAnalyzing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.analytics),
            onPressed: _isAnalyzing ? null : _triggerManualAnalysis,
            tooltip: 'Run Manual Analysis',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Patterns'),
            Tab(text: 'Predictions'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: $_error'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDashboardData,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPatternsTab(),
                _buildPredictionsTab(),
                _buildLogsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 2.w,
            childAspectRatio: 1.5,
            children: [
              _buildSummaryCard(
                'Active Threats',
                _activeThreats.toString(),
                Icons.warning,
                Colors.red,
              ),
              _buildSummaryCard(
                'Predicted Threats 24h',
                _predictedThreats24h.toString(),
                Icons.schedule,
                Colors.orange,
              ),
              _buildSummaryCard(
                'Analyzed Logs',
                _analyzedLogsToday.toString(),
                Icons.receipt_long,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Analysis Confidence',
                '${(_analysisConfidence * 100).toStringAsFixed(0)}%',
                Icons.verified,
                Colors.green,
              ),
            ],
          ),
          SizedBox(height: 3.h),

          if (_supabaseFraudSignals != null) ...[
            Text(
              'Internal signals (30d, Supabase)',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historical / forecasting inputs: ${_supabaseFraudSignals!['historicalData']}',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Threat correlation inputs: ${_supabaseFraudSignals!['threatData']}',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    if (_supabaseFraudSignals!['errors'] != null)
                      Padding(
                        padding: EdgeInsets.only(top: 1.h),
                        child: Text(
                          'Errors: ${_supabaseFraudSignals!['errors']}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 3.h),
          ],

          // Recent Analyses
          Text(
            'Recent Analyses',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          ..._recentAnalyses.map((analysis) => _buildAnalysisCard(analysis)),
        ],
      ),
    );
  }

  Widget _buildPatternsTab() {
    return _detectedPatterns.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                SizedBox(height: 16),
                Text('No fraud patterns detected'),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(3.w),
            itemCount: _detectedPatterns.length,
            itemBuilder: (context, index) {
              final pattern = _detectedPatterns[index];
              return _buildPatternCard(pattern);
            },
          );
  }

  Widget _buildPredictionsTab() {
    return _threatPredictions.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 48, color: Colors.green),
                SizedBox(height: 16),
                Text('No threats predicted'),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(3.w),
            itemCount: _threatPredictions.length,
            itemBuilder: (context, index) {
              final prediction = _threatPredictions[index];
              return _buildPredictionCard(prediction);
            },
          );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _searchLogs,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (_) => _searchLogs(),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedEventType,
                      decoration: InputDecoration(
                        labelText: 'Event Type',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                                'all',
                                'auth_event',
                                'payment_transaction',
                                'user_action',
                                'security_event',
                                'error',
                              ]
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEventType = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSeverity,
                      decoration: InputDecoration(
                        labelText: 'Severity',
                        border: OutlineInputBorder(),
                      ),
                      items: ['all', 'low', 'medium', 'high', 'critical']
                          .map(
                            (severity) => DropdownMenuItem(
                              value: severity,
                              child: Text(severity),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSeverity = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Search Results
        Expanded(
          child: _searchResults.isEmpty
              ? Center(child: Text('No results. Try searching for logs.'))
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final log = _searchResults[index];
                    return _buildLogCard(log);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
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
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(Map<String, dynamic> analysis) {
    final timestamp = DateTime.parse(analysis['analysis_timestamp'] as String);
    final patterns = analysis['detected_patterns'] as List? ?? [];
    final predictions = analysis['anomaly_predictions'] as List? ?? [];

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Icon(Icons.analytics, color: Colors.deepPurple),
        title: Text(
          'Analysis ${analysis['analysis_id'].toString().substring(0, 8)}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${patterns.length} patterns, ${predictions.length} predictions\n${timeago.format(timestamp)}',
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          // Show analysis details
        },
      ),
    );
  }

  Widget _buildPatternCard(Map<String, dynamic> pattern) {
    final confidence = pattern['confidence_score'] as num? ?? 0;
    final severity = pattern['severity'] as String? ?? 'low';
    final patternName = pattern['pattern_name'] as String? ?? 'Unknown';
    final description = pattern['pattern_description'] as String? ?? '';
    final affectedUsers = pattern['affected_users'] as List? ?? [];

    final severityColor = severity == 'critical'
        ? Colors.red
        : severity == 'high'
        ? Colors.orange
        : severity == 'medium'
        ? Colors.yellow.shade700
        : Colors.green;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ExpansionTile(
        leading: Icon(Icons.warning, color: severityColor),
        title: Text(patternName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.5.h),
            LinearProgressIndicator(
              value: confidence.toDouble(),
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                confidence > 0.8
                    ? Colors.green
                    : confidence > 0.6
                    ? Colors.yellow.shade700
                    : Colors.red,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text('Confidence: ${(confidence * 100).toStringAsFixed(0)}%'),
          ],
        ),
        trailing: Chip(
          label: Text(
            severity.toUpperCase(),
            style: TextStyle(color: Colors.white, fontSize: 10.sp),
          ),
          backgroundColor: severityColor,
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 0.5.h),
                Text(description),
                SizedBox(height: 1.h),
                Text(
                  'Affected Users: ${affectedUsers.length}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Recommended Actions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...(pattern['recommended_actions'] as List? ?? []).map(
                  (action) => Padding(
                    padding: EdgeInsets.only(top: 0.5.h),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 2.w),
                        Expanded(child: Text(action.toString())),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final threatType = prediction['predicted_threat'] as String? ?? 'Unknown';
    final likelihood = prediction['likelihood_percentage'] as int? ?? 0;
    final timeframe = prediction['predicted_timeframe'] as String? ?? 'Unknown';
    final warningSigns = prediction['warning_signs'] as List? ?? [];
    final preventiveActions = prediction['preventive_actions'] as List? ?? [];

    final likelihoodColor = likelihood >= 80
        ? Colors.red
        : likelihood >= 60
        ? Colors.orange
        : Colors.yellow.shade700;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ExpansionTile(
        leading: Icon(Icons.schedule, color: likelihoodColor),
        title: Text(threatType, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.5.h),
            LinearProgressIndicator(
              value: likelihood / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(likelihoodColor),
            ),
            SizedBox(height: 0.5.h),
            Text('Likelihood: $likelihood%'),
            Text('Timeframe: $timeframe'),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warning Signs:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...warningSigns.map(
                  (sign) => Padding(
                    padding: EdgeInsets.only(top: 0.5.h),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.orange),
                        SizedBox(width: 2.w),
                        Expanded(child: Text(sign.toString())),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Preventive Actions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...preventiveActions.map(
                  (action) => Padding(
                    padding: EdgeInsets.only(top: 0.5.h),
                    child: Row(
                      children: [
                        Icon(Icons.shield, size: 16, color: Colors.blue),
                        SizedBox(width: 2.w),
                        Expanded(child: Text(action.toString())),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final timestamp = DateTime.parse(log['timestamp'] as String);
    final eventType = log['event_type'] as String? ?? 'unknown';
    final severity = log['severity'] as String? ?? 'low';
    final action = log['action'] as String? ?? 'unknown';

    final severityColor = severity == 'critical'
        ? Colors.red
        : severity == 'high'
        ? Colors.orange
        : severity == 'medium'
        ? Colors.yellow.shade700
        : Colors.grey;

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        leading: Icon(Icons.receipt, color: severityColor),
        title: Text(
          action,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
        ),
        subtitle: Text(
          '$eventType • ${timeago.format(timestamp)}',
          style: TextStyle(fontSize: 12.sp),
        ),
        trailing: Chip(
          label: Text(
            severity,
            style: TextStyle(color: Colors.white, fontSize: 10.sp),
          ),
          backgroundColor: severityColor,
        ),
      ),
    );
  }
}
