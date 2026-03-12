import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';

class FeedOrchestrationEngineControlCenter extends StatefulWidget {
  const FeedOrchestrationEngineControlCenter({super.key});

  @override
  State<FeedOrchestrationEngineControlCenter> createState() =>
      _FeedOrchestrationEngineControlCenterState();
}

class _FeedOrchestrationEngineControlCenterState
    extends State<FeedOrchestrationEngineControlCenter> {
  final _supabase = SupabaseService.instance.client;
  Timer? _refreshTimer;
  bool _isLoading = true;

  Map<String, dynamic> _orchestrationStatus = {};
  List<Map<String, dynamic>> _contentScores = [];
  final List<Map<String, dynamic>> _routingDecisions = [];
  Map<String, dynamic> _performanceMetrics = {};

  @override
  void initState() {
    super.initState();
    _loadOrchestrationData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadOrchestrationData();
    });
  }

  Future<void> _loadOrchestrationData() async {
    try {
      // Load orchestration status
      final statusResponse = await _supabase
          .from('orchestration_performance_metrics')
          .select()
          .order('time_period', ascending: false)
          .limit(1)
          .single();

      // Load content scores
      final scoresResponse = await _supabase
          .from('content_orchestration_scores')
          .select()
          .order('final_score', ascending: false)
          .limit(20);

      // Load performance metrics
      final metricsResponse = await _supabase
          .from('carousel_performance_snapshots')
          .select()
          .order('snapshot_time', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _orchestrationStatus = statusResponse;
          _contentScores = List<Map<String, dynamic>>.from(scoresResponse);
          _performanceMetrics = {
            'snapshots': metricsResponse,
            'totalDistributed': _contentScores.length,
            'avgScore': _contentScores.isEmpty
                ? 0
                : _contentScores
                          .map((e) => e['final_score'] ?? 0)
                          .reduce((a, b) => a + b) /
                      _contentScores.length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed Orchestration Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrchestrationData,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Admin Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrchestrationData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusOverview(),
                    SizedBox(height: 2.h),
                    _buildContentScoringDashboard(),
                    SizedBox(height: 2.h),
                    _buildCarouselAssignmentLogic(),
                    SizedBox(height: 2.h),
                    _buildSequenceManagement(),
                    SizedBox(height: 2.h),
                    _buildDistributionMonitoring(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusOverview() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Orchestration Status',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCard(
                  'Active Processes',
                  '${_contentScores.length}',
                  Colors.green,
                ),
                _buildStatusCard(
                  'Avg Score',
                  '${_performanceMetrics['avgScore']?.toStringAsFixed(1) ?? '0'}',
                  Colors.blue,
                ),
                _buildStatusCard('Distribution Rate', '98.5%', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildContentScoringDashboard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Scoring Dashboard',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            ..._contentScores.take(5).map((score) => _buildScoreCard(score)),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(Map<String, dynamic> score) {
    final finalScore = score['final_score'] ?? 0;
    return Card(
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getScoreColor(finalScore),
          child: Text(
            '${finalScore.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('${score['content_type']} Content'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Base: ${score['base_engagement_score']?.toStringAsFixed(1) ?? '0'} | Recency: ${score['recency_score']?.toStringAsFixed(1) ?? '0'}',
            ),
            Text(
              'Social: ${score['social_proof_score']?.toStringAsFixed(1) ?? '0'} | Personal: ${score['personalization_score']?.toStringAsFixed(1) ?? '0'}',
            ),
          ],
        ),
        trailing: Text(
          '→ ${score['assigned_carousel'] ?? 'Pending'}',
          style: TextStyle(fontSize: 12.sp),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCarouselAssignmentLogic() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Carousel Assignment Logic',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            _buildAssignmentRule(
              'Jolts/Moments → Horizontal Snap',
              'High engagement content',
            ),
            _buildAssignmentRule(
              'Groups/Elections → Vertical Stack',
              'Decision-based content',
            ),
            _buildAssignmentRule(
              'Topics/Earners → Gradient Flow',
              'Discovery content',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentRule(String rule, String description) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      child: ListTile(
        leading: const Icon(Icons.arrow_forward, color: Colors.blue),
        title: Text(rule, style: TextStyle(fontSize: 14.sp)),
        subtitle: Text(
          description,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSequenceManagement() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sequence Management (Rhythm of 3)',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'Pattern: 2-3 Standard Posts → Carousel → Repeat',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: 0.65,
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Current Position: Post 2 of 3 before next carousel',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionMonitoring() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-Time Distribution Monitoring',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard(
                  'Feed Engagement',
                  '72.3%',
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Carousel Contribution',
                  '45%',
                  Icons.pie_chart,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'User Satisfaction',
                  '8.4/10',
                  Icons.star,
                  Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 30, color: color),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}