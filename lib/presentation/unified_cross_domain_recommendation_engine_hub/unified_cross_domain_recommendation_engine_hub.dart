import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/ai_recommendations_service.dart';
import '../../services/feed_ranking_service.dart';
import '../../services/openai_embeddings_service.dart';
import '../../services/topic_preference_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/ab_testing_widget.dart';
import './widgets/cold_start_solution_widget.dart';
import './widgets/cross_domain_engine_config_widget.dart';
import './widgets/openai_semantic_matching_widget.dart';
import './widgets/performance_analytics_widget.dart';
import './widgets/real_time_feed_ranking_widget.dart';

class UnifiedCrossDomainRecommendationEngineHub extends StatefulWidget {
  const UnifiedCrossDomainRecommendationEngineHub({super.key});

  @override
  State<UnifiedCrossDomainRecommendationEngineHub> createState() =>
      _UnifiedCrossDomainRecommendationEngineHubState();
}

class _UnifiedCrossDomainRecommendationEngineHubState
    extends State<UnifiedCrossDomainRecommendationEngineHub>
    with SingleTickerProviderStateMixin {
  final AIRecommendationsService _recommendationsService =
      AIRecommendationsService.instance;
  final FeedRankingService _feedRankingService = FeedRankingService.instance;
  final OpenAIEmbeddingsService _embeddingsService =
      OpenAIEmbeddingsService.instance;
  final TopicPreferenceService _topicPreferenceService =
      TopicPreferenceService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _engineStatus = {};
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadEngineData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEngineData() async {
    setState(() => _isLoading = true);

    try {
      final recommendations = await _recommendationsService
          .getContentRecommendations(screenContext: 'unified_feed', limit: 20);

      setState(() {
        _engineStatus = {
          'algorithm_performance': 92.5,
          'user_engagement_rate': 78.3,
          'ranking_effectiveness': 85.7,
          'active_users': 15420,
          'recommendations_served': 1247893,
        };
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'UnifiedCrossDomainRecommendationEngineHub',
      onRetry: _loadEngineData,
      child: Scaffold(
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
          title: 'Recommendation Engine Hub',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadEngineData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildStatusOverview(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        CrossDomainEngineConfigWidget(
                          onConfigChanged: _loadEngineData,
                        ),
                        RealTimeFeedRankingWidget(
                          recommendations: _recommendations,
                        ),
                        OpenAISemanticMatchingWidget(),
                        ColdStartSolutionWidget(),
                        ABTestingWidget(),
                        PerformanceAnalyticsWidget(engineStatus: _engineStatus),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusOverview() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendation Status',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusMetric(
                'Algorithm Performance',
                '${_engineStatus['algorithm_performance']?.toStringAsFixed(1) ?? '0.0'}%',
                Icons.psychology,
              ),
              _buildStatusMetric(
                'Engagement Rate',
                '${_engineStatus['user_engagement_rate']?.toStringAsFixed(1) ?? '0.0'}%',
                Icons.trending_up,
              ),
              _buildStatusMetric(
                'Ranking Effectiveness',
                '${_engineStatus['ranking_effectiveness']?.toStringAsFixed(1) ?? '0.0'}%',
                Icons.star,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 8.w),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Engine Config'),
          Tab(text: 'Feed Ranking'),
          Tab(text: 'Semantic Matching'),
          Tab(text: 'Cold Start'),
          Tab(text: 'A/B Testing'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }
}
