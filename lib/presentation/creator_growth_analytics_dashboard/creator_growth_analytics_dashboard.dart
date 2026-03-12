import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/claude_growth_coaching_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/action_plan_timeline_widget.dart';
import './widgets/growth_score_gauge_widget.dart';
import './widgets/growth_trajectory_chart_widget.dart';
import './widgets/opportunity_cards_widget.dart';
import './widgets/template_marketplace_roi_widget.dart';

class CreatorGrowthAnalyticsDashboard extends StatefulWidget {
  const CreatorGrowthAnalyticsDashboard({super.key});

  @override
  State<CreatorGrowthAnalyticsDashboard> createState() =>
      _CreatorGrowthAnalyticsDashboardState();
}

class _CreatorGrowthAnalyticsDashboardState
    extends State<CreatorGrowthAnalyticsDashboard> {
  final ClaudeGrowthCoachingService _coachingService =
      ClaudeGrowthCoachingService.instance;
  final AuthService _authService = AuthService.instance;

  bool _isLoading = true;
  bool _isRefreshing = false;
  GrowthAnalysisResult? _analysisResult;
  String? _error;
  dynamic _metricsSubscription;

  @override
  void initState() {
    super.initState();
    _loadGrowthAnalysis();
  }

  @override
  void dispose() {
    _metricsSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadGrowthAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        setState(() {
          _analysisResult = GrowthAnalysisResult.fallback;
          _isLoading = false;
        });
        return;
      }

      final result = await _coachingService.analyzeCreatorGrowth(userId);

      // Store prediction
      await _coachingService.storeGrowthPrediction(
        userId: userId,
        result: result,
      );

      // Subscribe to real-time updates
      _metricsSubscription = _coachingService.subscribeToCreatorMetrics(
        userId,
        () => _refreshAnalysis(),
      );

      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _analysisResult = GrowthAnalysisResult.fallback;
        _isLoading = false;
        _error = 'Using cached analysis';
      });
    }
  }

  Future<void> _refreshAnalysis() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadGrowthAnalysis();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'CreatorGrowthAnalyticsDashboard',
      onRetry: _loadGrowthAnalysis,
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
          title: 'Growth Analytics',
          actions: [
            if (_isRefreshing)
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: SizedBox(
                  width: 5.w,
                  height: 5.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.vibrantYellow,
                    ),
                  ),
                ),
              )
            else
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  size: 6.w,
                  color: AppTheme.textPrimaryLight,
                ),
                onPressed: _refreshAnalysis,
              ),
          ],
        ),
        body: _isLoading ? _buildLoadingState() : _buildContent(theme),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        SkeletonCard(height: 20.h),
        SizedBox(height: 2.h),
        SkeletonCard(height: 15.h),
        SizedBox(height: 2.h),
        SkeletonCard(height: 25.h),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    final result = _analysisResult ?? GrowthAnalysisResult.fallback;

    return RefreshIndicator(
      onRefresh: _refreshAnalysis,
      color: AppTheme.vibrantYellow,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          // Status header
          _buildStatusHeader(theme, result),
          SizedBox(height: 2.h),

          // Growth Score Gauge
          GrowthScoreGaugeWidget(
            score: result.growthScore,
            trajectory: result.trajectory,
            confidenceScore: result.confidenceScore,
          ),
          SizedBox(height: 2.h),

          // Opportunity Cards
          OpportunityCardsWidget(opportunities: result.opportunities),
          SizedBox(height: 2.h),

          // Content Strategy Panel
          _buildContentStrategyPanel(theme, result.contentStrategy),
          SizedBox(height: 2.h),

          // Revenue Acceleration Tactics
          _buildRevenueTacticsPanel(theme, result.revenueTactics),
          SizedBox(height: 2.h),

          // Growth Trajectory Chart
          GrowthTrajectoryChartWidget(
            growthPrediction: result.growthPrediction,
          ),
          SizedBox(height: 2.h),

          // Template Marketplace ROI
          TemplateMarketplaceROIWidget(templateROI: result.templateROI),
          SizedBox(height: 2.h),

          // Action Plan Timeline
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: ActionPlanTimelineWidget(actionPlan: result.actionPlan),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme, GrowthAnalysisResult result) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.vibrantYellow.withAlpha(26),
            const Color(0xFF8B5CF6).withAlpha(26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.vibrantYellow.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.5.w),
            decoration: BoxDecoration(
              color: AppTheme.vibrantYellow,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(Icons.psychology, color: Colors.white, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Claude Growth Coach',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _error ?? 'ML-powered personalized insights',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: _error != null
                        ? AppTheme.vibrantYellow
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF10B981).withAlpha(77)),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentStrategyPanel(
    ThemeData theme,
    Map<String, dynamic> strategy,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.vibrantYellow,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Content Strategy',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _StrategyRow(
            icon: Icons.schedule,
            label: 'Best Time',
            value: strategy['optimal_posting_time'] as String? ?? 'N/A',
          ),
          _StrategyRow(
            icon: Icons.video_library,
            label: 'Best Format',
            value: strategy['best_content_type'] as String? ?? 'N/A',
          ),
          _StrategyRow(
            icon: Icons.repeat,
            label: 'Frequency',
            value: strategy['recommended_frequency'] as String? ?? 'N/A',
          ),
          _StrategyRow(
            icon: Icons.tips_and_updates,
            label: 'Pro Tip',
            value: strategy['engagement_tip'] as String? ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTacticsPanel(
    ThemeData theme,
    List<Map<String, dynamic>> tactics,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rocket_launch,
                color: const Color(0xFF10B981),
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Revenue Acceleration',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          ...tactics.map(
            (tactic) => Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 2.w,
                    height: 2.w,
                    margin: EdgeInsets.only(top: 1.h, right: 2.w),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tactic['tactic'] as String? ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          tactic['description'] as String? ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StrategyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 4.w, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 2.w),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}