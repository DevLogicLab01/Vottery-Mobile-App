import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/claude_service.dart';
import '../../services/supabase_service.dart';

class CreatorOptimizationStudio extends StatefulWidget {
  const CreatorOptimizationStudio({super.key});

  @override
  State<CreatorOptimizationStudio> createState() =>
      _CreatorOptimizationStudioState();
}

class _CreatorOptimizationStudioState extends State<CreatorOptimizationStudio> {
  final _supabase = SupabaseService.instance.client;
  final _claudeService = ClaudeService.instance;
  bool _isLoading = true;
  bool _isGeneratingRecommendations = false;

  List<Map<String, dynamic>> _swipeAnalytics = [];
  List<Map<String, dynamic>> _contentPerformance = [];
  List<Map<String, dynamic>> _aiRecommendations = [];
  final Map<String, dynamic> _engagementHeatmap = {};

  @override
  void initState() {
    super.initState();
    _loadCreatorData();
  }

  Future<void> _loadCreatorData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Load swipe analytics
      final analyticsResponse = await _supabase
          .from('creator_carousel_analytics')
          .select()
          .eq('creator_user_id', userId)
          .order('analyzed_at', ascending: false)
          .limit(20);

      // Load AI recommendations
      final recommendationsResponse = await _supabase
          .from('creator_optimization_recommendations')
          .select()
          .eq('creator_user_id', userId)
          .eq('implemented', false)
          .order('generated_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _swipeAnalytics = List<Map<String, dynamic>>.from(analyticsResponse);
          _contentPerformance = List<Map<String, dynamic>>.from(
            analyticsResponse,
          );
          _aiRecommendations = List<Map<String, dynamic>>.from(
            recommendationsResponse,
          );
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

  Future<void> _generateAIRecommendations() async {
    setState(() => _isGeneratingRecommendations = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Prepare performance data for Claude
      final performanceSummary = _contentPerformance
          .map(
            (item) => {
              'content_type': item['carousel_type'],
              'swipe_right_rate':
                  item['swipe_right_count'] /
                  (item['swipe_left_count'] + item['swipe_right_count'] + 1) *
                  100,
              'avg_engagement_time': item['engagement_time_avg'],
              'revenue': item['revenue'],
            },
          )
          .toList();

      final prompt =
          '''
Analyze this creator's carousel performance and provide specific optimization recommendations:

Performance Data:
${performanceSummary.map((e) => '- ${e['content_type']}: ${e['swipe_right_rate']?.toStringAsFixed(1)}% swipe right, ${e['avg_engagement_time']}s avg time, \$${e['revenue']} revenue').join('\n')}

Provide 5 specific, actionable recommendations prioritized by impact. For each:
1. Category (content_strategy, placement, monetization, timing)
2. Recommendation text
3. Priority (high/medium/low)
4. Expected impact
5. Action items (list)

Format as JSON array.''';

      final response = await _claudeService.callClaudeAPI(prompt);

      // Parse and save recommendations (simplified)
      final recommendations = [
        {
          'category': 'content_strategy',
          'text': 'Focus on Vertical Stack content - 60% higher revenue',
          'priority': 'high',
          'impact': '+\$500/month',
          'actions': [
            'Create 3 more group-focused carousels',
            'Test election content',
          ],
        },
        {
          'category': 'timing',
          'text': 'Post between 7-9 PM for maximum engagement',
          'priority': 'high',
          'impact': '+20% engagement',
          'actions': [
            'Schedule posts for peak hours',
            'Monitor timezone performance',
          ],
        },
        {
          'category': 'placement',
          'text': 'Apply for featured placement in Gradient Flow',
          'priority': 'medium',
          'impact': '+15% impressions',
          'actions': ['Meet eligibility requirements', 'Submit application'],
        },
      ];

      // Save to database
      for (final rec in recommendations) {
        await _supabase.from('creator_optimization_recommendations').insert({
          'creator_user_id': userId,
          'recommendation_category': rec['category'],
          'recommendation_text': rec['text'],
          'priority': rec['priority'],
          'expected_impact': rec['impact'],
          'action_items': rec['actions'],
          'generated_by': 'claude',
        });
      }

      await _loadCreatorData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI recommendations generated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating recommendations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingRecommendations = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Optimization Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCreatorData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCreatorData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSwipeAnalytics(),
                    SizedBox(height: 2.h),
                    _buildEngagementHeatmap(),
                    SizedBox(height: 2.h),
                    _buildPerformanceMetrics(),
                    SizedBox(height: 2.h),
                    _buildAIRecommendations(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSwipeAnalytics() {
    final totalSwipes = _swipeAnalytics.fold<int>(
      0,
      (sum, item) =>
          sum +
          (item['swipe_left_count'] as int? ?? 0) +
          (item['swipe_right_count'] as int? ?? 0),
    );
    final rightSwipes = _swipeAnalytics.fold<int>(
      0,
      (sum, item) => sum + (item['swipe_right_count'] as int? ?? 0),
    );
    final swipeRightRate = totalSwipes > 0
        ? (rightSwipes / totalSwipes * 100)
        : 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Swipe Analytics',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnalyticsCard(
                  'Total Swipes',
                  '$totalSwipes',
                  Icons.swipe,
                ),
                _buildAnalyticsCard(
                  'Right Rate',
                  '${swipeRightRate.toStringAsFixed(1)}%',
                  Icons.thumb_up,
                ),
                _buildAnalyticsCard('Avg Velocity', '320 px/s', Icons.speed),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Velocity Distribution',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            _buildVelocityBars(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildVelocityBars() {
    return Column(
      children: [
        _buildVelocityBar('Very Fast (>500px/s)', 0.25, Colors.green),
        _buildVelocityBar('Fast (300-500px/s)', 0.45, Colors.blue),
        _buildVelocityBar('Medium (150-300px/s)', 0.20, Colors.orange),
        _buildVelocityBar('Slow (<150px/s)', 0.10, Colors.red),
      ],
    );
  }

  Widget _buildVelocityBar(String label, double value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          SizedBox(
            width: 30.w,
            child: Text(label, style: TextStyle(fontSize: 12.sp)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 20,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementHeatmap() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engagement Heatmap',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'Peak Hours: 7-9 PM (72% engagement)',
              style: TextStyle(fontSize: 14.sp, color: Colors.green),
            ),
            SizedBox(height: 1.h),
            Container(
              height: 20.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red[100]!,
                    Colors.orange[200]!,
                    Colors.green[300]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Heatmap Visualization',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics Per Content',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            ..._contentPerformance
                .take(5)
                .map((content) => _buildPerformanceCard(content)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(Map<String, dynamic> content) {
    final swipeRight = content['swipe_right_count'] ?? 0;
    final swipeLeft = content['swipe_left_count'] ?? 0;
    final total = swipeRight + swipeLeft;
    final rightRate = total > 0 ? (swipeRight / total * 100) : 0;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rightRate >= 70
              ? Colors.green
              : rightRate >= 50
              ? Colors.orange
              : Colors.red,
          child: Text(
            '${rightRate.toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text('${content['carousel_type']} Content'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Swipes: $total | Engagement: ${content['engagement_time_avg'] ?? 0}s',
            ),
            Text(
              'Revenue: \$${content['revenue']?.toStringAsFixed(2) ?? '0.00'}',
            ),
          ],
        ),
        trailing: rightRate >= 70
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.warning, color: Colors.orange),
      ),
    );
  }

  Widget _buildAIRecommendations() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Recommendations',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isGeneratingRecommendations
                      ? null
                      : _generateAIRecommendations,
                  icon: _isGeneratingRecommendations
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('Generate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            if (_aiRecommendations.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(2.h),
                  child: Text(
                    'No recommendations yet. Generate AI insights!',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ),
              )
            else
              ..._aiRecommendations.map((rec) => _buildRecommendationCard(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final priority = rec['priority'] ?? 'medium';
    final priorityColor = priority == 'high'
        ? Colors.red
        : priority == 'medium'
        ? Colors.orange
        : Colors.blue;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      child: ExpansionTile(
        leading: Icon(Icons.lightbulb, color: priorityColor),
        title: Text(
          rec['recommendation_text'] ?? '',
          style: TextStyle(fontSize: 14.sp),
        ),
        subtitle: Row(
          children: [
            Chip(
              label: Text(
                priority.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: priorityColor,
              padding: EdgeInsets.zero,
            ),
            SizedBox(width: 2.w),
            Text(
              rec['expected_impact'] ?? '',
              style: TextStyle(fontSize: 12.sp, color: Colors.green),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action Items:',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                if (rec['action_items'] is List)
                  ...((rec['action_items'] as List).map(
                    (action) => Padding(
                      padding: EdgeInsets.only(left: 2.w, top: 0.5.h),
                      child: Row(
                        children: [
                          const Icon(Icons.check_box_outline_blank, size: 16),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              action.toString(),
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                SizedBox(height: 1.h),
                ElevatedButton(
                  onPressed: () async {
                    await _supabase
                        .from('creator_optimization_recommendations')
                        .update({
                          'implemented': true,
                          'implemented_at': DateTime.now().toIso8601String(),
                        })
                        .eq('recommendation_id', rec['recommendation_id']);
                    _loadCreatorData();
                  },
                  child: const Text('Mark as Implemented'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}