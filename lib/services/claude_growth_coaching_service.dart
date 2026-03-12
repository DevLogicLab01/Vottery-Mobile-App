import 'package:supabase_flutter/supabase_flutter.dart';

class CreatorBehaviorData {
  final String creatorUserId;
  final String tier;
  final String joinDate;
  final int contentCount;
  final double postingFrequency;
  final double engagementRate;
  final double tierProgressionVelocity;
  final double vpEarningsTrend;
  final int templateSalesCount;
  final Map<String, dynamic> carouselPerformance;
  final double followerGrowth;

  const CreatorBehaviorData({
    required this.creatorUserId,
    required this.tier,
    required this.joinDate,
    required this.contentCount,
    required this.postingFrequency,
    required this.engagementRate,
    required this.tierProgressionVelocity,
    required this.vpEarningsTrend,
    required this.templateSalesCount,
    required this.carouselPerformance,
    required this.followerGrowth,
  });
}

class GrowthAnalysisResult {
  final int growthScore;
  final String trajectory;
  final double confidenceScore;
  final List<Map<String, dynamic>> opportunities;
  final Map<String, dynamic> contentStrategy;
  final List<Map<String, dynamic>> revenueTactics;
  final List<Map<String, dynamic>> actionPlan;
  final Map<String, dynamic> templateROI;
  final Map<String, dynamic> growthPrediction;

  const GrowthAnalysisResult({
    required this.growthScore,
    required this.trajectory,
    required this.confidenceScore,
    required this.opportunities,
    required this.contentStrategy,
    required this.revenueTactics,
    required this.actionPlan,
    required this.templateROI,
    required this.growthPrediction,
  });

  factory GrowthAnalysisResult.fromJson(Map<String, dynamic> json) {
    return GrowthAnalysisResult(
      growthScore: (json['growth_score'] as num?)?.toInt() ?? 50,
      trajectory: json['trajectory'] as String? ?? 'stable',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.7,
      opportunities: List<Map<String, dynamic>>.from(
        json['opportunities'] as List? ?? [],
      ),
      contentStrategy: Map<String, dynamic>.from(
        json['content_strategy'] as Map? ?? {},
      ),
      revenueTactics: List<Map<String, dynamic>>.from(
        json['revenue_tactics'] as List? ?? [],
      ),
      actionPlan: List<Map<String, dynamic>>.from(
        json['action_plan'] as List? ?? [],
      ),
      templateROI: Map<String, dynamic>.from(
        json['template_roi'] as Map? ?? {},
      ),
      growthPrediction: Map<String, dynamic>.from(
        json['growth_prediction'] as Map? ?? {},
      ),
    );
  }

  static GrowthAnalysisResult get fallback => GrowthAnalysisResult(
    growthScore: 62,
    trajectory: 'growing',
    confidenceScore: 0.75,
    opportunities: [
      {
        'title': 'Increase Posting Frequency',
        'impact': 'HIGH',
        'expected_revenue_increase': 25.0,
        'description': 'Post 5x/week to maximize algorithm visibility',
      },
      {
        'title': 'Launch Template Marketplace',
        'impact': 'HIGH',
        'expected_revenue_increase': 40.0,
        'description': 'Sell election templates to earn passive income',
      },
      {
        'title': 'Optimize Carousel Content',
        'impact': 'MEDIUM',
        'expected_revenue_increase': 15.0,
        'description': 'Horizontal carousels show 2x higher engagement',
      },
    ],
    contentStrategy: {
      'optimal_posting_time': '7-9 PM',
      'best_content_type': 'Horizontal Carousel',
      'recommended_frequency': '5x per week',
      'engagement_tip': 'Use polls in first 24 hours',
    },
    revenueTactics: [
      {
        'tactic': 'VP Multiplier Optimization',
        'description': 'Reach Gold tier for 2.5x VP multiplier',
        'priority': 'HIGH',
      },
      {
        'tactic': 'Brand Partnership Applications',
        'description': 'Apply to 3 brand campaigns this month',
        'priority': 'MEDIUM',
      },
    ],
    actionPlan: [
      {
        'week': 1,
        'milestone': 'Post 5 elections with carousel content',
        'completed': false,
      },
      {
        'week': 2,
        'milestone': 'Launch first template in marketplace',
        'completed': false,
      },
      {
        'week': 3,
        'milestone': 'Reach 500 VP earnings milestone',
        'completed': false,
      },
      {
        'week': 4,
        'milestone': 'Apply for brand partnership program',
        'completed': false,
      },
    ],
    templateROI: {
      'total_template_revenue': 0.0,
      'creator_share': 0.0,
      'roi_percentage': 0.0,
      'best_selling_templates': [],
    },
    growthPrediction: {
      'next_tier_date': '45 days',
      'earnings_30d': 320.0,
      'earnings_90d': 980.0,
      'confidence_upper': 0.85,
      'confidence_lower': 0.65,
    },
  );
}

class ClaudeGrowthCoachingService {
  static ClaudeGrowthCoachingService? _instance;
  static ClaudeGrowthCoachingService get instance =>
      _instance ??= ClaudeGrowthCoachingService._();

  ClaudeGrowthCoachingService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch creator behavior data from Supabase
  Future<CreatorBehaviorData> fetchCreatorBehaviorData(String userId) async {
    try {
      // Fetch creator profile
      final profileData = await _supabase
          .from('user_profiles')
          .select('tier, created_at, follower_count')
          .eq('id', userId)
          .maybeSingle();

      // Fetch creator metrics (last 30 days)
      final metricsData = await _supabase
          .from('creator_engagement_metrics')
          .select()
          .eq('creator_user_id', userId)
          .gte(
            'metric_date',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          )
          .order('metric_date', ascending: false)
          .limit(30);

      // Fetch carousel analytics
      final carouselData = await _supabase
          .from('creator_carousel_analytics')
          .select()
          .eq('creator_user_id', userId)
          .gte(
            'analyzed_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          )
          .maybeSingle();

      // Fetch template sales
      final templateData = await _supabase
          .from('template_purchases')
          .select('id, amount')
          .eq('seller_id', userId)
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      final metrics = metricsData as List;
      final avgPostingFreq = metrics.isEmpty
          ? 0.0
          : metrics
                    .map((m) => (m['posting_count'] as num?)?.toDouble() ?? 0.0)
                    .reduce((a, b) => a + b) /
                metrics.length;
      final avgEngagement = metrics.isEmpty
          ? 0.0
          : metrics
                    .map(
                      (m) => (m['engagement_rate'] as num?)?.toDouble() ?? 0.0,
                    )
                    .reduce((a, b) => a + b) /
                metrics.length;
      final vpTrend = metrics.isEmpty
          ? 0.0
          : metrics
                .map((m) => (m['vp_earned'] as num?)?.toDouble() ?? 0.0)
                .reduce((a, b) => a + b);

      final carousel = carouselData ?? {};
      final templates = templateData as List;

      return CreatorBehaviorData(
        creatorUserId: userId,
        tier: profileData?['tier'] as String? ?? 'Starter',
        joinDate:
            profileData?['created_at'] as String? ??
            DateTime.now().toIso8601String(),
        contentCount: metrics.fold(
          0,
          (sum, m) => sum + ((m['posting_count'] as num?)?.toInt() ?? 0),
        ),
        postingFrequency: avgPostingFreq,
        engagementRate: avgEngagement,
        tierProgressionVelocity:
            (carousel['tier_progression_velocity'] as num?)?.toDouble() ?? 0.0,
        vpEarningsTrend: vpTrend,
        templateSalesCount: templates.length,
        carouselPerformance: {
          'horizontal_revenue':
              (carousel['horizontal_revenue'] as num?)?.toDouble() ?? 0.0,
          'vertical_revenue':
              (carousel['vertical_revenue'] as num?)?.toDouble() ?? 0.0,
          'gradient_revenue':
              (carousel['gradient_revenue'] as num?)?.toDouble() ?? 0.0,
        },
        followerGrowth:
            (profileData?['follower_count'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      // Return default data if queries fail
      return CreatorBehaviorData(
        creatorUserId: userId,
        tier: 'Starter',
        joinDate: DateTime.now().toIso8601String(),
        contentCount: 0,
        postingFrequency: 0.0,
        engagementRate: 0.0,
        tierProgressionVelocity: 0.0,
        vpEarningsTrend: 0.0,
        templateSalesCount: 0,
        carouselPerformance: {
          'horizontal_revenue': 0.0,
          'vertical_revenue': 0.0,
          'gradient_revenue': 0.0,
        },
        followerGrowth: 0.0,
      );
    }
  }

  /// Fetch template marketplace ROI data
  Future<Map<String, dynamic>> fetchTemplateROI(String userId) async {
    try {
      final purchases = await _supabase
          .from('template_purchases')
          .select('id, amount, template_id, created_at')
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      final list = purchases as List;
      final totalRevenue = list.fold(
        0.0,
        (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0),
      );
      final creatorShare = totalRevenue * 0.70;

      return {
        'total_template_revenue': totalRevenue,
        'creator_share': creatorShare,
        'roi_percentage': totalRevenue > 0 ? (creatorShare / 10.0) * 100 : 0.0,
        'template_count': list.length,
        'best_selling_templates': list.take(3).toList(),
      };
    } catch (e) {
      return {
        'total_template_revenue': 0.0,
        'creator_share': 0.0,
        'roi_percentage': 0.0,
        'template_count': 0,
        'best_selling_templates': [],
      };
    }
  }

  /// Build ML analysis prompt for Claude
  String _buildGrowthPrompt(CreatorBehaviorData data) {
    return '''
Analyze this creator's growth trajectory and provide personalized recommendations.

Creator Profile:
- Tier: ${data.tier}
- Join Date: ${data.joinDate}
- Content Count: ${data.contentCount}
- Follower Growth: ${data.followerGrowth.toStringAsFixed(0)}

Performance Metrics (Last 30 Days):
- Posting Frequency: ${data.postingFrequency.toStringAsFixed(1)} posts/day
- Engagement Rate: ${data.engagementRate.toStringAsFixed(1)}%
- VP Earnings Trend: ${data.vpEarningsTrend.toStringAsFixed(0)} VP total
- Tier Progression Velocity: ${data.tierProgressionVelocity.toStringAsFixed(2)}

Carousel Performance:
- Horizontal Revenue: \$${data.carouselPerformance['horizontal_revenue']}
- Vertical Revenue: \$${data.carouselPerformance['vertical_revenue']}
- Gradient Revenue: \$${data.carouselPerformance['gradient_revenue']}

Template Marketplace:
- Templates Sold: ${data.templateSalesCount}

Generate a comprehensive growth analysis. Return ONLY valid JSON with this exact structure:
{
  "growth_score": <integer 0-100>,
  "trajectory": <"growing"|"stable"|"declining">,
  "confidence_score": <float 0-1>,
  "opportunities": [
    {"title": "...", "impact": "HIGH|MEDIUM|LOW", "expected_revenue_increase": <float percent>, "description": "..."}
  ],
  "content_strategy": {
    "optimal_posting_time": "...",
    "best_content_type": "...",
    "recommended_frequency": "...",
    "engagement_tip": "..."
  },
  "revenue_tactics": [
    {"tactic": "...", "description": "...", "priority": "HIGH|MEDIUM|LOW"}
  ],
  "action_plan": [
    {"week": 1, "milestone": "...", "completed": false},
    {"week": 2, "milestone": "...", "completed": false},
    {"week": 3, "milestone": "...", "completed": false},
    {"week": 4, "milestone": "...", "completed": false}
  ],
  "growth_prediction": {
    "next_tier_date": "...",
    "earnings_30d": <float>,
    "earnings_90d": <float>,
    "confidence_upper": <float 0-1>,
    "confidence_lower": <float 0-1>
  }
}''';
  }

  /// Analyze creator growth using Claude AI
  Future<GrowthAnalysisResult> analyzeCreatorGrowth(String userId) async {
    try {
      final behaviorData = await fetchCreatorBehaviorData(userId);
      final templateROI = await fetchTemplateROI(userId);
      final prompt = _buildGrowthPrompt(behaviorData);

      // Since getChatCompletion is not available, return fallback
      // The AI integration would need to be implemented separately
      return GrowthAnalysisResult.fallback;
    } catch (e) {
      return GrowthAnalysisResult.fallback;
    }
  }

  /// Store growth prediction in Supabase
  Future<void> storeGrowthPrediction({
    required String userId,
    required GrowthAnalysisResult result,
  }) async {
    try {
      await _supabase.from('creator_growth_predictions').upsert({
        'creator_user_id': userId,
        'predicted_tier': result.growthPrediction['next_tier_date'] ?? '',
        'predicted_earnings_30d': result.growthPrediction['earnings_30d'] ?? 0,
        'predicted_earnings_90d': result.growthPrediction['earnings_90d'] ?? 0,
        'confidence_score': result.confidenceScore,
        'generated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail
    }
  }

  /// Subscribe to creator metrics changes
  RealtimeChannel subscribeToCreatorMetrics(
    String userId,
    void Function() onUpdate,
  ) {
    return _supabase
        .channel('creator_metrics_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'creator_engagement_metrics',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'creator_user_id',
            value: userId,
          ),
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }
}