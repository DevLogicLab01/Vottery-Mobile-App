import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/election_insights_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/demographic_pie_chart_widget.dart';
import './widgets/engagement_heatmap_grid_widget.dart';
import './widgets/outcome_predictions_widget.dart';
import './widgets/strategic_recommendations_widget.dart';
import './widgets/swing_voters_widget.dart';
import './widgets/voting_trends_chart_widget.dart';

/// Mobile Election Insights Analytics
/// OpenAI GPT-5 powered predictive modeling with touch-friendly
/// data visualization optimized for mobile consumption
class MobileElectionInsightsAnalytics extends StatefulWidget {
  final String? electionId;

  const MobileElectionInsightsAnalytics({super.key, this.electionId});

  @override
  State<MobileElectionInsightsAnalytics> createState() =>
      _MobileElectionInsightsAnalyticsState();
}

class _MobileElectionInsightsAnalyticsState
    extends State<MobileElectionInsightsAnalytics>
    with SingleTickerProviderStateMixin {
  final ElectionInsightsService _insightsService =
      ElectionInsightsService.instance;
  late TabController _tabController;

  String? _electionId;
  bool _isLoading = true;
  bool _isGenerating = false;

  Map<String, dynamic>? _predictions;
  List<Map<String, dynamic>> _votingTrends = [];
  List<Map<String, dynamic>> _demographics = [];
  List<Map<String, dynamic>> _swingVoters = [];
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _engagementHeatmap = [];
  List<Map<String, dynamic>> _correlations = [];
  Map<String, dynamic> _momentum = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _electionId = widget.electionId;
    if (_electionId != null) {
      _loadAnalytics();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    if (_electionId == null) return;

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _insightsService.getPredictions(_electionId!),
        _insightsService.getVotingTrends(_electionId!),
        _insightsService.getDemographicBreakdown(_electionId!),
        _insightsService.getSwingVoters(_electionId!),
        _insightsService.getRecommendations(_electionId!),
        _insightsService.getEngagementHeatmap(_electionId!),
        _insightsService.getDemographicCorrelations(_electionId!),
        _insightsService.getVoteMomentum(_electionId!),
      ]);

      setState(() {
        _predictions = results[0] as Map<String, dynamic>?;
        _votingTrends = results[1] as List<Map<String, dynamic>>;
        _demographics = results[2] as List<Map<String, dynamic>>;
        _swingVoters = results[3] as List<Map<String, dynamic>>;
        _recommendations = results[4] as List<Map<String, dynamic>>;
        _engagementHeatmap = results[5] as List<Map<String, dynamic>>;
        _correlations = results[6] as List<Map<String, dynamic>>;
        _momentum = results[7] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load analytics error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePredictions() async {
    if (_electionId == null) return;

    setState(() => _isGenerating = true);
    try {
      await _insightsService.generatePredictions(_electionId!);
      await _loadAnalytics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Predictions generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Generate predictions error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateRecommendations() async {
    if (_electionId == null) return;

    setState(() => _isGenerating = true);
    try {
      await _insightsService.generateRecommendations(_electionId!);
      await _loadAnalytics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recommendations generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Generate recommendations error: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _shareInsights() async {
    if (_electionId == null) return;

    try {
      final report = await _insightsService.generateShareableReport(
        _electionId!,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share Insights'),
            content: const Text(
              'Report generated. Export as PDF or share via email.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report exported as PDF')),
                  );
                },
                child: const Text('Export PDF'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Share insights error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_electionId == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Election Insights',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 15.w, color: Colors.grey),
              SizedBox(height: 2.h),
              Text(
                'No election selected',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Election Insights',
        variant: CustomAppBarVariant.withBack,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareInsights,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Demographics'),
              Tab(text: 'Engagement'),
              Tab(text: 'Strategy'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildDemographicsTab(),
                      _buildEngagementTab(),
                      _buildStrategyTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          // Outcome Predictions
          OutcomePredictionsWidget(
            predictions: _predictions,
            onGenerate: _generatePredictions,
            isGenerating: _isGenerating,
          ),
          SizedBox(height: 2.h),

          // Vote Momentum
          Card(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vote Momentum',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(
                        _momentum['direction'] == 'up'
                            ? Icons.trending_up
                            : _momentum['direction'] == 'down'
                            ? Icons.trending_down
                            : Icons.trending_flat,
                        color: _momentum['direction'] == 'up'
                            ? Colors.green
                            : _momentum['direction'] == 'down'
                            ? Colors.red
                            : Colors.grey,
                        size: 8.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${(_momentum['momentum'] ?? 0.0).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: _momentum['direction'] == 'up'
                              ? Colors.green
                              : _momentum['direction'] == 'down'
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Voting Trends Chart
          VotingTrendsChartWidget(trends: _votingTrends),
        ],
      ),
    );
  }

  Widget _buildDemographicsTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        // Demographic Breakdown
        DemographicPieChartWidget(demographics: _demographics),
        SizedBox(height: 2.h),

        // Swing Voters
        SwingVotersWidget(swingVoters: _swingVoters),
      ],
    );
  }

  Widget _buildEngagementTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        // Engagement Heatmap
        EngagementHeatmapGridWidget(heatmapData: _engagementHeatmap),
        SizedBox(height: 2.h),

        // Demographic Correlations
        Card(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Most Engaged Groups',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                ..._correlations.take(5).map((correlation) {
                  final group = correlation['demographic_group'] as String;
                  final rate =
                      (correlation['engagement_rate'] as num?)?.toDouble() ??
                      0.0;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(group, style: TextStyle(fontSize: 12.sp)),
                        ),
                        Text(
                          '${rate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrategyTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        // Strategic Recommendations
        StrategicRecommendationsWidget(
          recommendations: _recommendations,
          onGenerate: _generateRecommendations,
          isGenerating: _isGenerating,
        ),
      ],
    );
  }
}
