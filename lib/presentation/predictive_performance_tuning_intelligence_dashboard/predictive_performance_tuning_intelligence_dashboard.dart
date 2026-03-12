import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/predictive_performance_tuning_service.dart';
import './widgets/capacity_prediction_card_widget.dart';
import './widgets/cost_optimization_card_widget.dart';
import './widgets/index_card_widget.dart';
import './widgets/performance_pattern_card_widget.dart';
import './widgets/recommendation_card_widget.dart';

class PredictivePerformanceTuningIntelligenceDashboard extends StatefulWidget {
  const PredictivePerformanceTuningIntelligenceDashboard({super.key});

  @override
  State<PredictivePerformanceTuningIntelligenceDashboard> createState() =>
      _PredictivePerformanceTuningIntelligenceDashboardState();
}

class _PredictivePerformanceTuningIntelligenceDashboardState
    extends State<PredictivePerformanceTuningIntelligenceDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = PredictivePerformanceTuningService.instance;

  PerformanceTuningAnalysis? _analysis;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _errorMessage;

  static const _tabs = [
    Tab(text: 'Patterns'),
    Tab(text: 'Recommendations'),
    Tab(text: 'Indexes'),
    Tab(text: 'Predictions'),
    Tab(text: 'Costs'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadLatestAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestAnalysis() async {
    setState(() => _isLoading = true);
    try {
      final analysis = await _service.getLatestAnalysis();
      setState(() {
        _analysis = analysis ?? _service.cachedAnalysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });
    try {
      final analysis = await _service.analyzePerformancePatterns();
      setState(() {
        _analysis = analysis;
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perplexity analysis complete'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Performance Tuning AI',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isAnalyzing)
            Padding(
              padding: EdgeInsets.all(2.w),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.psychology),
              tooltip: 'Run Perplexity Analysis',
              onPressed: _runAnalysis,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLatestAnalysis,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
          tabs: _tabs,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysis == null
          ? _buildEmptyState()
          : _buildTabContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 60,
            color: Colors.indigo.shade300,
          ),
          SizedBox(height: 2.h),
          Text(
            'No analysis available',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 1.h),
          Text(
            'Run Perplexity analysis to get AI-powered\nperformance recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _runAnalysis,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run Analysis Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    final analysis = _analysis!;
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPatternsTab(analysis),
        _buildRecommendationsTab(analysis),
        _buildIndexesTab(analysis),
        _buildPredictionsTab(analysis),
        _buildCostsTab(analysis),
      ],
    );
  }

  Widget _buildPatternsTab(PerformanceTuningAnalysis analysis) {
    return Column(
      children: [
        _AnalysisHeader(
          title: 'Performance Patterns',
          subtitle:
              '${analysis.patterns.length} patterns identified • ${_formatDate(analysis.analysisDate)}',
          icon: Icons.pattern,
          color: Colors.red.shade600,
        ),
        Expanded(
          child: analysis.patterns.isEmpty
              ? _buildNoData('No patterns found')
              : ListView.builder(
                  itemCount: analysis.patterns.length,
                  itemBuilder: (_, i) =>
                      PerformancePatternCard(pattern: analysis.patterns[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsTab(PerformanceTuningAnalysis analysis) {
    return Column(
      children: [
        _AnalysisHeader(
          title: 'Query Recommendations',
          subtitle:
              '${analysis.recommendations.length} optimizations available',
          icon: Icons.auto_fix_high,
          color: Colors.purple.shade600,
        ),
        Expanded(
          child: analysis.recommendations.isEmpty
              ? _buildNoData('No recommendations found')
              : ListView.builder(
                  itemCount: analysis.recommendations.length,
                  itemBuilder: (_, i) => RecommendationCard(
                    recommendation: analysis.recommendations[i],
                    onApply: _service.applyQueryRecommendation,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildIndexesTab(PerformanceTuningAnalysis analysis) {
    return Column(
      children: [
        _AnalysisHeader(
          title: 'Index Optimization',
          subtitle: '${analysis.indexes.length} missing indexes detected',
          icon: Icons.storage,
          color: Colors.teal.shade600,
        ),
        Expanded(
          child: analysis.indexes.isEmpty
              ? _buildNoData('No index recommendations')
              : ListView.builder(
                  itemCount: analysis.indexes.length,
                  itemBuilder: (_, i) => IndexCard(
                    index: analysis.indexes[i],
                    onApply: _service.applyIndexRecommendation,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPredictionsTab(PerformanceTuningAnalysis analysis) {
    return Column(
      children: [
        _AnalysisHeader(
          title: 'Capacity Predictions',
          subtitle: '24h & 48h forecasts with confidence scores',
          icon: Icons.timeline,
          color: Colors.blue.shade600,
        ),
        Expanded(
          child: analysis.predictions.isEmpty
              ? _buildNoData('No predictions available')
              : ListView.builder(
                  itemCount: analysis.predictions.length,
                  itemBuilder: (_, i) => CapacityPredictionCard(
                    prediction: analysis.predictions[i],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCostsTab(PerformanceTuningAnalysis analysis) {
    final totalSavings = analysis.costs.fold(
      0.0,
      (sum, c) => sum + c.monthlySavings,
    );
    return Column(
      children: [
        _AnalysisHeader(
          title: 'Cost Optimization',
          subtitle:
              '\$${totalSavings.toStringAsFixed(0)}/month potential savings',
          icon: Icons.savings,
          color: Colors.green.shade600,
        ),
        Expanded(
          child: analysis.costs.isEmpty
              ? _buildNoData('No cost optimizations found')
              : ListView.builder(
                  itemCount: analysis.costs.length,
                  itemBuilder: (_, i) =>
                      CostOptimizationCard(optimization: analysis.costs[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildNoData(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
          SizedBox(height: 1.h),
          Text(
            message,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AnalysisHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _AnalysisHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      color: color.withAlpha(20),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
