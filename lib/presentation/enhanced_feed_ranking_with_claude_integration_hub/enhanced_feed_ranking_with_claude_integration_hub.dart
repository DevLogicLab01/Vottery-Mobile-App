import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/claude_service.dart';
import '../../services/feed_ranking_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/behavioral_pattern_analysis_widget.dart';
import './widgets/semantic_content_matching_widget.dart';
import './widgets/contextual_feed_ordering_widget.dart';
import './widgets/recommendation_explanation_widget.dart';
import './widgets/claude_reasoning_dashboard_widget.dart';
import './widgets/ab_testing_framework_widget.dart';
import './widgets/real_time_adaptation_widget.dart';
import './widgets/feed_performance_overview_widget.dart';

/// Enhanced Feed Ranking with Claude Integration Hub
/// Implements Claude Sonnet 4.5 API for contextual reasoning and
/// personalized content discovery optimization
class EnhancedFeedRankingWithClaudeIntegrationHub extends StatefulWidget {
  const EnhancedFeedRankingWithClaudeIntegrationHub({super.key});

  @override
  State<EnhancedFeedRankingWithClaudeIntegrationHub> createState() =>
      _EnhancedFeedRankingWithClaudeIntegrationHubState();
}

class _EnhancedFeedRankingWithClaudeIntegrationHubState
    extends State<EnhancedFeedRankingWithClaudeIntegrationHub>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _client = SupabaseService.instance.client;
  final AuthService _authService = AuthService.instance;
  final ClaudeService _claudeService = ClaudeService.instance;
  final FeedRankingService _feedRankingService = FeedRankingService.instance;

  late TabController _tabController;

  bool _isLoading = true;
  bool _isAdmin = false;
  Map<String, dynamic>? _feedPerformanceMetrics;
  Map<String, dynamic>? _behavioralPatterns;
  List<Map<String, dynamic>> _semanticMatches = [];
  Map<String, dynamic>? _claudeReasoningInsights;
  Map<String, dynamic>? _abTestingResults;
  Map<String, dynamic>? _adaptationMetrics;
  String _claudeApiStatus = 'checking';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      // Check admin status
      final userProfile = await _client
          .from('user_profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      _isAdmin = [
        'admin',
        'super_admin',
      ].contains(userProfile?['role'] as String?);

      if (!_isAdmin) {
        setState(() => _isLoading = false);
        return;
      }

      // Check Claude API status
      await _checkClaudeAPIStatus();

      final results = await Future.wait<dynamic>([
        _loadFeedPerformanceMetrics(),
        _loadBehavioralPatterns(userId),
        _loadSemanticMatches(userId),
        _loadClaudeReasoningInsights(userId),
        _loadABTestingResults(),
        _loadAdaptationMetrics(),
      ]);

      if (mounted) {
        setState(() {
          _feedPerformanceMetrics = results[0] as Map<String, dynamic>?;
          _behavioralPatterns = results[1] as Map<String, dynamic>?;
          _semanticMatches = results[2] as List<Map<String, dynamic>>? ?? [];
          _claudeReasoningInsights = results[3] as Map<String, dynamic>?;
          _abTestingResults = results[4] as Map<String, dynamic>?;
          _adaptationMetrics = results[5] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load dashboard data error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkClaudeAPIStatus() async {
    try {
      const apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        setState(() => _claudeApiStatus = 'not_configured');
        return;
      }

      // Test API call
      final testResult = await _claudeService.getContextualRecommendations(
        screenContext: 'feed_ranking_test',
        userData: {'test': true},
      );

      setState(() {
        _claudeApiStatus = testResult.isNotEmpty ? 'active' : 'error';
      });
    } catch (e) {
      setState(() => _claudeApiStatus = 'error');
    }
  }

  Future<Map<String, dynamic>> _loadFeedPerformanceMetrics() async {
    final response = await _client
        .from('feed_ranking_metrics')
        .select()
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response ?? {};
  }

  Future<Map<String, dynamic>> _loadBehavioralPatterns(String userId) async {
    final votingHistory = await _client
        .from('votes')
        .select('election_id, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);

    final interactions = await _client
        .from('engagement_signals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);

    final socialConnections = await _client
        .from('user_connections')
        .select()
        .or('requester_id.eq.$userId,addressee_id.eq.$userId')
        .eq('status', 'accepted');

    return {
      'voting_frequency': votingHistory.length,
      'interaction_count': interactions.length,
      'social_connections': socialConnections.length,
      'avg_time_spent': _calculateAvgTimeSpent(interactions),
    };
  }

  double _calculateAvgTimeSpent(List<dynamic> interactions) {
    if (interactions.isEmpty) return 0.0;

    final totalSeconds = interactions.fold<int>(0, (sum, item) {
      return sum + (item['view_duration_seconds'] as int? ?? 0);
    });

    return totalSeconds / interactions.length;
  }

  Future<List<Map<String, dynamic>>> _loadSemanticMatches(String userId) async {
    final response = await _client
        .from('personalized_rankings')
        .select('*, election:elections(*)')
        .eq('user_id', userId)
        .gte('confidence_score', 0.7)
        .order('confidence_score', ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> _loadClaudeReasoningInsights(
    String userId,
  ) async {
    try {
      final userBehavior = await _loadBehavioralPatterns(userId);

      final insights = await _claudeService.getContextualRecommendations(
        screenContext: 'feed_ranking_analysis',
        userData: userBehavior,
      );

      return {
        'insights': insights,
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Load Claude insights error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadABTestingResults() async {
    final response = await _client
        .from('feed_ranking_ab_tests')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response ?? {};
  }

  Future<Map<String, dynamic>> _loadAdaptationMetrics() async {
    final response = await _client
        .from('feed_adaptation_metrics')
        .select()
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response ?? {};
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedFeedRankingWithClaudeIntegrationHub',
      onRetry: _loadDashboardData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Enhanced Feed Ranking',
          actions: [
            _buildClaudeStatusIndicator(theme),
            SizedBox(width: 2.w),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              onPressed: _refreshDashboard,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : !_isAdmin
            ? _buildAccessDenied(theme)
            : RefreshIndicator(
                onRefresh: _refreshDashboard,
                child: Column(
                  children: [
                    // Feed Performance Overview
                    FeedPerformanceOverviewWidget(
                      metrics: _feedPerformanceMetrics,
                      claudeApiStatus: _claudeApiStatus,
                    ),

                    // Tabs
                    TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurface
                          .withAlpha(153),
                      indicatorColor: theme.colorScheme.primary,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Analysis'),
                        Tab(text: 'Matching'),
                        Tab(text: 'Claude AI'),
                        Tab(text: 'Testing'),
                      ],
                    ),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Analysis Tab
                          _buildAnalysisTab(theme),

                          // Matching Tab
                          _buildMatchingTab(theme),

                          // Claude AI Tab
                          _buildClaudeAITab(theme),

                          // Testing Tab
                          _buildTestingTab(theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildClaudeStatusIndicator(ThemeData theme) {
    Color statusColor;
    String statusIcon;

    switch (_claudeApiStatus) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = 'check_circle';
        break;
      case 'not_configured':
        statusColor = Colors.orange;
        statusIcon = 'warning';
        break;
      case 'error':
        statusColor = Colors.red;
        statusIcon = 'error';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = 'sync';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          CustomIconWidget(iconName: statusIcon, color: statusColor, size: 16),
          SizedBox(width: 1.w),
          Text(
            'Claude',
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Behavioral Pattern Analysis',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          BehavioralPatternAnalysisWidget(patterns: _behavioralPatterns),
          SizedBox(height: 3.h),
          Text(
            'Real-time Adaptation',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          RealTimeAdaptationWidget(metrics: _adaptationMetrics),
        ],
      ),
    );
  }

  Widget _buildMatchingTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semantic Content Matching',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          SemanticContentMatchingWidget(matches: _semanticMatches),
          SizedBox(height: 3.h),
          Text(
            'Contextual Feed Ordering',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          ContextualFeedOrderingWidget(matches: _semanticMatches),
        ],
      ),
    );
  }

  Widget _buildClaudeAITab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Claude Reasoning Dashboard',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          ClaudeReasoningDashboardWidget(insights: _claudeReasoningInsights),
          SizedBox(height: 3.h),
          Text(
            'Recommendation Explanations',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          RecommendationExplanationWidget(insights: _claudeReasoningInsights),
        ],
      ),
    );
  }

  Widget _buildTestingTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A/B Testing Framework',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          ABTestingFrameworkWidget(results: _abTestingResults),
        ],
      ),
    );
  }

  Widget _buildAccessDenied(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'lock',
            color: theme.colorScheme.onSurface.withAlpha(77),
            size: 60,
          ),
          SizedBox(height: 2.h),
          Text(
            'Admin Access Required',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'This dashboard is only accessible to content administrators',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          SkeletonCard(height: 12.h, width: double.infinity),
          SizedBox(height: 2.h),
          SkeletonCard(height: 20.h, width: double.infinity),
          SizedBox(height: 2.h),
          SkeletonCard(height: 15.h, width: double.infinity),
        ],
      ),
    );
  }
}
