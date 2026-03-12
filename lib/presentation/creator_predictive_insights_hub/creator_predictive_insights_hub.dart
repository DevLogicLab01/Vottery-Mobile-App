import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

class CreatorPredictiveInsightsHub extends ConsumerStatefulWidget {
  const CreatorPredictiveInsightsHub({super.key});

  @override
  ConsumerState<CreatorPredictiveInsightsHub> createState() =>
      _CreatorPredictiveInsightsHubState();
}

class _CreatorPredictiveInsightsHubState
    extends ConsumerState<CreatorPredictiveInsightsHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingInsights = false;
  bool _hasGeneratedInsights = false;

  final Map<String, dynamic> _creatorProfile = {
    'name': 'Creator Dashboard',
    'tier': 'Gold',
    'total_elections': 47,
    'avg_participation': 342,
    'top_categories': ['Politics', 'Sports', 'Entertainment'],
    'monthly_revenue': 2840.0,
    'growth_rate': 18.4,
    'audience_size': 8920,
  };

  late List<Map<String, dynamic>> _topicInsights;
  late List<Map<String, dynamic>> _timingInsights;
  late List<Map<String, dynamic>> _pricingInsights;
  late List<Map<String, dynamic>> _roiProjections;

  final List<Map<String, dynamic>> _peerBenchmarks = [
    {
      'metric': 'Avg Participation Rate',
      'your_value': '342',
      'peer_avg': '287',
      'top_10_pct': '580',
      'status': 'above_avg',
    },
    {
      'metric': 'Revenue per Election',
      'your_value': '\$60.4',
      'peer_avg': '\$48.2',
      'top_10_pct': '\$124.8',
      'status': 'above_avg',
    },
    {
      'metric': 'Audience Growth Rate',
      'your_value': '18.4%',
      'peer_avg': '12.1%',
      'top_10_pct': '34.7%',
      'status': 'above_avg',
    },
    {
      'metric': 'MCQ Completion Rate',
      'your_value': '67.3%',
      'peer_avg': '71.8%',
      'top_10_pct': '89.2%',
      'status': 'below_avg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDefaultInsights();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDefaultInsights() {
    _topicInsights = [
      {
        'topic': 'Local Government Elections',
        'trend_score': 87,
        'predicted_participation': 420,
        'reasoning':
            'High civic engagement trend in Q1; local elections drive 2.3x more repeat voters',
        'confidence': 91,
        'category': 'Politics',
        'icon': 'how_to_vote',
        'color': Colors.blue,
      },
      {
        'topic': 'Sports Championship Predictions',
        'trend_score': 94,
        'predicted_participation': 580,
        'reasoning':
            'Championship season drives peak engagement; sports elections have 34% higher MCQ completion',
        'confidence': 88,
        'category': 'Sports',
        'icon': 'sports_soccer',
        'color': Colors.green,
      },
      {
        'topic': 'Tech Product Launches',
        'trend_score': 79,
        'predicted_participation': 310,
        'reasoning':
            'Tech-savvy audience segment growing 28% YoY; product launch elections monetize well',
        'confidence': 82,
        'category': 'Technology',
        'icon': 'devices',
        'color': Colors.purple,
      },
    ];

    _timingInsights = [
      {
        'window': 'Tuesday 7-9 PM',
        'engagement_multiplier': 2.1,
        'reasoning':
            'Your audience peaks on weekday evenings; Tuesday has lowest competition from other creators',
        'confidence': 89,
        'recommended_for': 'High-stakes elections',
      },
      {
        'window': 'Saturday 10 AM - 12 PM',
        'engagement_multiplier': 1.8,
        'reasoning':
            'Weekend morning leisure browsing; ideal for longer MCQ elections requiring focus',
        'confidence': 84,
        'recommended_for': 'MCQ-heavy elections',
      },
      {
        'window': 'Sunday 3-5 PM',
        'engagement_multiplier': 1.6,
        'reasoning':
            'Pre-week planning mindset; good for political/civic topics',
        'confidence': 77,
        'recommended_for': 'Civic/political topics',
      },
    ];

    _pricingInsights = [
      {
        'strategy': 'Tiered Participation Fees',
        'recommended_price': '\$0.50 - \$2.00',
        'projected_revenue_lift': '+42%',
        'reasoning':
            'Your audience has 67% premium tier penetration; tiered pricing captures willingness-to-pay variance',
        'confidence': 86,
        'risk_level': 'Low',
      },
      {
        'strategy': 'Early Bird Discount (First 2h)',
        'recommended_price': '20% off standard',
        'projected_revenue_lift': '+28%',
        'reasoning':
            'Creates urgency and front-loads participation; early voters drive social proof for late adopters',
        'confidence': 79,
        'risk_level': 'Low',
      },
      {
        'strategy': 'Bundle Pricing (3 elections)',
        'recommended_price': '\$3.99 bundle',
        'projected_revenue_lift': '+61%',
        'reasoning':
            'Bundle pricing increases LTV by 2.4x; reduces churn between election cycles',
        'confidence': 73,
        'risk_level': 'Medium',
      },
    ];

    _roiProjections = [
      {
        'scenario': 'Conservative (Current Pace)',
        'monthly_revenue_30d': 2840,
        'monthly_revenue_90d': 3200,
        'audience_growth_30d': 8.2,
        'audience_growth_90d': 24.1,
        'tier_advancement': 'Stay Gold',
        'confidence': 94,
        'color': Colors.blue,
      },
      {
        'scenario': 'Optimized (Apply Recommendations)',
        'monthly_revenue_30d': 3890,
        'monthly_revenue_90d': 5640,
        'audience_growth_30d': 14.7,
        'audience_growth_90d': 48.3,
        'tier_advancement': 'Advance to Platinum',
        'confidence': 78,
        'color': Colors.green,
      },
      {
        'scenario': 'Aggressive (Max Monetization)',
        'monthly_revenue_30d': 4820,
        'monthly_revenue_90d': 8100,
        'audience_growth_30d': 19.3,
        'audience_growth_90d': 67.8,
        'tier_advancement': 'Advance to Diamond',
        'confidence': 54,
        'color': Colors.purple,
      },
    ];
  }

  Future<void> _generateAIInsights() async {
    setState(() => _isLoadingInsights = true);
    final prompt =
        'Analyze this creator profile and provide strategic insights:\n'
        'Tier: ${_creatorProfile['tier']}, Elections: ${_creatorProfile['total_elections']}, '
        'Avg Participation: ${_creatorProfile['avg_participation']}, '
        'Categories: ${(_creatorProfile['top_categories'] as List).join(', ')}, '
        'Revenue: \$${_creatorProfile['monthly_revenue']}/mo, Growth: ${_creatorProfile['growth_rate']}%, '
        'Audience: ${_creatorProfile['audience_size']}\n\n'
        'Provide: 1) Top 3 election topics for next 30 days with engagement predictions, '
        '2) Optimal timing windows, 3) Pricing strategies with ROI projections. '
        'Be specific with confidence percentages and data-driven reasoning.';

    setState(() {
      _isLoadingInsights = false;
      _hasGeneratedInsights = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: 'Predictive Creator Insights',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(38),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.purple.withAlpha(102)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔮', style: TextStyle(fontSize: 12.sp)),
                  SizedBox(width: 1.w),
                  Text(
                    'Perplexity AI',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCreatorProfileHeader(),
          _buildAIInsightsPanel(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTopicsTab(),
                _buildTimingTab(),
                _buildPricingTab(),
                _buildROITab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorProfileHeader() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withAlpha(38),
            AppTheme.primaryLight.withAlpha(26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.purple.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            width: 14.w,
            height: 14.w,
            decoration: BoxDecoration(
              color: Colors.purple.withAlpha(51),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Center(
              child: Text('🏆', style: TextStyle(fontSize: 18.sp)),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _creatorProfile['name'] as String,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(51),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        '${_creatorProfile['tier']} Tier',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.amber[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${_creatorProfile['total_elections']} elections · ${_creatorProfile['audience_size']} audience · +${_creatorProfile['growth_rate']}% growth',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${_creatorProfile['monthly_revenue']}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                'monthly',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsPanel() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.purple.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('🔮', style: TextStyle(fontSize: 14.sp)),
                  SizedBox(width: 2.w),
                  Text(
                    'Perplexity Extended Reasoning',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _isLoadingInsights
                    ? null
                    : _generateAIInsights,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
                child: _isLoadingInsights
                    ? SizedBox(
                        width: 4.w,
                        height: 4.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _hasGeneratedInsights ? 'Refresh' : 'Generate Insights',
                        style: TextStyle(fontSize: 11.sp),
                      ),
              ),
            ],
          ),
          if (_isLoadingInsights) ...[
            SizedBox(height: 1.5.h),
            Container(
              constraints: BoxConstraints(maxHeight: 15.h),
              child: SingleChildScrollView(
                child: Text(
                  'Analyzing your creator patterns with extended reasoning...',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
          if (!_isLoadingInsights && !_hasGeneratedInsights) ...[
            SizedBox(height: 1.h),
            Text(
              'Tap "Generate Insights" for personalized AI analysis of your creator patterns',
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.only(top: 2.h),
      color: AppTheme.surfaceLight,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: '📊 Topics'),
          Tab(text: '⏰ Timing'),
          Tab(text: '💰 Pricing'),
          Tab(text: '📈 ROI'),
        ],
      ),
    );
  }

  Widget _buildTopicsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Recommended Election Topics',
            'AI-predicted high-engagement topics based on your audience patterns',
            Colors.blue,
          ),
          SizedBox(height: 2.h),
          ..._topicInsights.map((insight) => _buildTopicCard(insight)),
          SizedBox(height: 2.h),
          _buildPeerBenchmarkSection(),
        ],
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> insight) {
    final color = insight['color'] as Color;
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: insight['icon'] as String,
                    size: 5.w,
                    color: color,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight['topic'] as String,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      insight['category'] as String,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${insight['trend_score']}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'trend score',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              insight['reasoning'] as String,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'people',
                    size: 4.w,
                    color: AppTheme.textSecondaryLight,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '~${insight['predicted_participation']} predicted voters',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${insight['confidence']}% confidence',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeerBenchmarkSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peer Benchmarking',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Your performance vs Gold tier peers',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.5.h),
          ..._peerBenchmarks.map((bench) => _buildBenchmarkRow(bench)),
        ],
      ),
    );
  }

  Widget _buildBenchmarkRow(Map<String, dynamic> bench) {
    final isAbove = bench['status'] == 'above_avg';
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              bench['metric'] as String,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  bench['your_value'] as String,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: isAbove ? Colors.green : Colors.orange,
                  ),
                ),
                Text(
                  'You',
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  bench['peer_avg'] as String,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  'Avg',
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  bench['top_10_pct'] as String,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.purple,
                  ),
                ),
                Text(
                  'Top 10%',
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: isAbove ? 'arrow_upward' : 'arrow_downward',
            size: 4.w,
            color: isAbove ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildTimingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Optimal Launch Windows',
            'AI-predicted best times to launch elections for maximum engagement',
            Colors.orange,
          ),
          SizedBox(height: 2.h),
          ..._timingInsights.asMap().entries.map(
            (entry) => _buildTimingCard(entry.value, entry.key + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingCard(Map<String, dynamic> insight, int rank) {
    final multiplier = insight['engagement_multiplier'] as double;
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: rank == 1
              ? Colors.orange.withAlpha(128)
              : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: rank == 1
                      ? Colors.orange.withAlpha(51)
                      : Colors.grey.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: rank == 1
                          ? Colors.orange
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight['window'] as String,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Best for: ${insight['recommended_for']}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${multiplier}x',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'engagement',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              insight['reasoning'] as String,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                '${insight['confidence']}% confidence',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Pricing Strategy Recommendations',
            'Optimize revenue without reducing participation rates',
            Colors.green,
          ),
          SizedBox(height: 2.h),
          ..._pricingInsights.map((insight) => _buildPricingCard(insight)),
        ],
      ),
    );
  }

  Widget _buildPricingCard(Map<String, dynamic> insight) {
    final riskLevel = insight['risk_level'] as String;
    final riskColor = riskLevel == 'Low'
        ? Colors.green
        : riskLevel == 'Medium'
        ? Colors.orange
        : Colors.red;
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  insight['strategy'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '$riskLevel Risk',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: riskColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildPricingMetric(
                  'Recommended Price',
                  insight['recommended_price'] as String,
                  'attach_money',
                  Colors.blue,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildPricingMetric(
                  'Revenue Lift',
                  insight['projected_revenue_lift'] as String,
                  'trending_up',
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              insight['reasoning'] as String,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${insight['confidence']}% confidence',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Strategy applied to next election'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                ),
                child: Text('Apply', style: TextStyle(fontSize: 11.sp)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingMetric(
    String label,
    String value,
    String icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          CustomIconWidget(iconName: icon, size: 5.w, color: color),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildROITab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'ROI Projections',
            '30-day and 90-day forecasts based on strategy adoption',
            Colors.purple,
          ),
          SizedBox(height: 2.h),
          ..._roiProjections.map((proj) => _buildROICard(proj)),
        ],
      ),
    );
  }

  Widget _buildROICard(Map<String, dynamic> proj) {
    final color = proj['color'] as Color;
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  proj['scenario'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${proj['confidence']}% confidence',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _buildROIMetric(
                  '30-Day Revenue',
                  '\$${proj['monthly_revenue_30d']}',
                  color,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildROIMetric(
                  '90-Day Revenue',
                  '\$${proj['monthly_revenue_90d']}',
                  color,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _buildROIMetric(
                  '30-Day Growth',
                  '+${proj['audience_growth_30d']}%',
                  Colors.teal,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildROIMetric(
                  '90-Day Growth',
                  '+${proj['audience_growth_90d']}%',
                  Colors.teal,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'military_tech',
                  size: 5.w,
                  color: color,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    proj['tier_advancement'] as String,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildROIMetric(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }
}