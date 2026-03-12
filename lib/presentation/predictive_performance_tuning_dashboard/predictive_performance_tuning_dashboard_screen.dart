import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../services/predictive_performance_tuning_service.dart';
import './widgets/performance_pattern_card_widget.dart';
import './widgets/recommendation_card_widget.dart';
import './widgets/capacity_prediction_card_widget.dart';

class PredictivePerformanceTuningDashboardScreen extends StatefulWidget {
  const PredictivePerformanceTuningDashboardScreen({super.key});

  @override
  State<PredictivePerformanceTuningDashboardScreen> createState() =>
      _PredictivePerformanceTuningDashboardScreenState();
}

class _PredictivePerformanceTuningDashboardScreenState
    extends State<PredictivePerformanceTuningDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = PredictivePerformanceTuningService.instance;
  bool _isAnalyzing = false;
  PerformanceTuningAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    final results = await _service.getLatestAnalysis();
    if (results != null && mounted) {
      setState(() => _analysis = results);
    } else {
      // Use mock data immediately
      final mock = await _service.analyzePerformancePatterns();
      if (mounted) setState(() => _analysis = mock);
    }
  }

  Future<void> _runAnalysis() async {
    setState(() => _isAnalyzing = true);
    try {
      final result = await _service.analyzePerformancePatterns();
      if (mounted) setState(() => _analysis = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perplexity analysis complete'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  List<Map<String, dynamic>> get _patterns {
    final raw = _analysis?.patterns;
    if (raw != null) {
      return raw
          .map(
            (p) => {
              'description': p.description,
              'root_cause': p.rootCause,
              'severity': p.severity,
              'metrics': p.metrics,
            },
          )
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> get _recommendations {
    final raw = _analysis?.recommendations;
    if (raw != null) {
      return raw
          .map(
            (r) => {
              'recommendation_type': r.recommendationType,
              'current_query': r.currentQuery,
              'optimized_query': r.optimizedQuery,
              'expected_improvement': r.expectedImprovement,
              'explain_analyze': r.explainAnalyze,
            },
          )
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> get _indexes {
    final raw = _analysis?.indexes;
    if (raw != null) {
      return raw
          .map(
            (i) => {
              'table': i.tableName,
              'column': i.columnName,
              'create_index_statement': i.createIndexStatement,
              'expected_impact': i.expectedImpact,
              'affected_queries': i.affectedQueries,
            },
          )
          .toList();
    }
    return [];
  }

  Map<String, dynamic> get _predictions {
    final raw = _analysis?.predictions;
    if (raw != null && raw.isNotEmpty) {
      final map = <String, dynamic>{};
      for (final p in raw) {
        if (p.horizon == '24h') {
          map['predicted_users_24h'] = p.predictedUsers;
          map['predicted_connections_24h'] = p.predictedDatabaseConnections;
          map['predicted_memory_24h'] = p.predictedMemoryGb;
        } else if (p.horizon == '48h') {
          map['predicted_users_48h'] = p.predictedUsers;
          map['predicted_connections_48h'] = p.predictedDatabaseConnections;
          map['predicted_memory_48h'] = p.predictedMemoryGb;
        }
        map['confidence_score'] = p.confidenceScore;
      }
      return map;
    }
    return {};
  }

  List<Map<String, dynamic>> get _costs {
    final raw = _analysis?.costs;
    if (raw != null) {
      return raw
          .map(
            (c) => {
              'optimization': c.title,
              'savings_monthly': c.monthlySavings,
              'implementation_effort': c.implementationEffort,
            },
          )
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Performance Tuning AI',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15.sp,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isAnalyzing ? null : _runAnalysis,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology, size: 18),
              label: Text(
                _isAnalyzing ? 'Analyzing...' : 'Run AI',
                style: GoogleFonts.inter(fontSize: 11.sp),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11.sp),
          tabs: const [
            Tab(text: 'Patterns'),
            Tab(text: 'Recommendations'),
            Tab(text: 'Indexes'),
            Tab(text: 'Predictions'),
            Tab(text: 'Costs'),
          ],
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPatternsTab(),
          _buildRecommendationsTab(),
          _buildIndexesTab(),
          _buildPredictionsTab(),
          _buildCostsTab(),
        ],
      ),
    );
  }

  Widget _buildPatternsTab() {
    return _patterns.isEmpty
        ? _buildEmptyState('No patterns analyzed yet', Icons.search)
        : ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: _patterns.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PerformancePatternCardWidget(pattern: _patterns[i]),
            ),
          );
  }

  Widget _buildRecommendationsTab() {
    return _recommendations.isEmpty
        ? _buildEmptyState('No recommendations yet', Icons.auto_fix_high)
        : ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: _recommendations.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecommendationCardWidget(
                recommendation: _recommendations[i],
                onApply: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📋 Implementation guide shown'),
                    ),
                  );
                },
              ),
            ),
          );
  }

  Widget _buildIndexesTab() {
    return _indexes.isEmpty
        ? _buildEmptyState('No index recommendations', Icons.storage)
        : ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: _indexes.length,
            itemBuilder: (_, i) {
              final idx = _indexes[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${idx['table']}.${idx['column']}',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          idx['create_index_statement'] as String? ?? '',
                          style: GoogleFonts.inter(fontSize: 10.sp),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '📈 ${idx['expected_impact']}',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildPredictionsTab() {
    if (_predictions.isEmpty) {
      return _buildEmptyState('No predictions available', Icons.timeline);
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          CapacityPredictionCardWidget(
            timeframe: '24h',
            predictedUsers:
                (_predictions['predicted_users_24h'] as num?)?.toInt() ?? 0,
            predictedConnections:
                (_predictions['predicted_connections_24h'] as num?)?.toInt() ??
                0,
            predictedMemory:
                (_predictions['predicted_memory_24h'] as num?)?.toDouble() ?? 0,
            confidenceScore:
                (_predictions['confidence_score'] as num?)?.toDouble() ?? 0,
          ),
          SizedBox(height: 2.h),
          CapacityPredictionCardWidget(
            timeframe: '48h',
            predictedUsers:
                (_predictions['predicted_users_48h'] as num?)?.toInt() ?? 0,
            predictedConnections:
                (_predictions['predicted_connections_48h'] as num?)?.toInt() ??
                0,
            predictedMemory:
                (_predictions['predicted_memory_24h'] as num?)?.toDouble() ?? 0,
            confidenceScore:
                (_predictions['confidence_score'] as num?)?.toDouble() ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildCostsTab() {
    return _costs.isEmpty
        ? _buildEmptyState('No cost optimizations found', Icons.attach_money)
        : ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: _costs.length,
            itemBuilder: (_, i) {
              final cost = _costs[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.savings,
                      color: Colors.green[600],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    cost['optimization'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Save \$${cost['savings_monthly']}/month · ${cost['implementation_effort']} effort',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          SizedBox(height: 2.h),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: _runAnalysis,
            icon: const Icon(Icons.psychology, size: 18),
            label: const Text('Run Perplexity Analysis'),
          ),
        ],
      ),
    );
  }
}
