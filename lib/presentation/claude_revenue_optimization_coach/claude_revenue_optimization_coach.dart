import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../services/creator_coaching_service.dart';

/// Mobile Creator Coaching Hub
///
/// Lightweight, touch-optimized view that surfaces:
/// - Key creator revenue metrics (from Supabase snapshots)
/// - Anthropic Claude coaching summary
/// - 3–5 prioritized recommendations and concrete next steps
///
/// This screen intentionally mirrors the spirit of the Web
/// Creator Earnings Command Center + Claude coaching, but
/// in a simplified mobile format.
class ClaudeRevenueOptimizationCoachScreen extends StatefulWidget {
  const ClaudeRevenueOptimizationCoachScreen({super.key});

  @override
  State<ClaudeRevenueOptimizationCoachScreen> createState() =>
      _ClaudeRevenueOptimizationCoachScreenState();
}

class _ClaudeRevenueOptimizationCoachScreenState
    extends State<ClaudeRevenueOptimizationCoachScreen> {
  final _service = CreatorCoachingService.instance;

  bool _loading = true;
  String? _error;
  CreatorCoachingResult? _result;

  @override
  void initState() {
    super.initState();
    _loadCoaching();
  }

  Future<void> _loadCoaching() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getCoachingSummary();
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'ClaudeRevenueOptimizationCoach',
      onRetry: _loadCoaching,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Creator Coaching',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadCoaching,
          child: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const SkeletonDashboard();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 32.sp, color: theme.colorScheme.error),
              SizedBox(height: 2.h),
              Text(
                'We could not load your coaching insights right now.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                _error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: _loadCoaching,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_result == null) {
      return EnhancedEmptyStateWidget(
        title: 'No insights yet',
        message:
            'Start running elections and campaigns to unlock personalized coaching.',
        primaryActionLabel: 'Refresh',
        onPrimaryAction: _loadCoaching,
      );
    }

    final result = _result!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(result, theme),
          SizedBox(height: 2.5.h),
          _buildInsightsSection(result, theme),
          SizedBox(height: 2.5.h),
          _buildNextStepsSection(result, theme),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CreatorCoachingResult result, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_graph,
                    color: AppTheme.accentLight,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Claude Revenue Coach',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.6.h),
            Text(
              result.summary.isNotEmpty
                  ? result.summary
                  : 'Claude will help you optimize your earnings, content, and pacing based on your recent performance.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(
      CreatorCoachingResult result, ThemeData theme) {
    final insights = result.priorityInsights;
    if (insights.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Priority insights',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 0.8.h),
          Text(
            'We will surface specific insights here as more data accumulates.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority insights',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.2.h),
        ...insights.map((insight) {
          final title = (insight['title'] as String?) ?? 'Insight';
          final description =
              (insight['description'] as String?) ?? 'No description provided.';
          final impact = (insight['impact'] as String?) ?? 'medium';
          final timeframe = (insight['timeframe'] as String?) ?? 'this month';

          final impactColor = switch (impact.toLowerCase()) {
            'high' => Colors.redAccent,
            'medium' => AppTheme.accentLight,
            _ => AppTheme.primaryLight,
          };

          return Container(
            margin: EdgeInsets.only(bottom: 1.6.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.15),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(3.2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: impactColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.8.h),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.8.h),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          'Impact: ${impact[0].toUpperCase()}${impact.substring(1)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: impactColor.shade700,
                          ),
                        ),
                        backgroundColor: impactColor.withOpacity(0.12),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      SizedBox(width: 2.w),
                      Chip(
                        label: Text(
                          timeframe,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNextStepsSection(
      CreatorCoachingResult result, ThemeData theme) {
    final steps = result.nextSteps;
    if (steps.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next steps',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 0.8.h),
          Text(
            'As Claude gathers more data, actionable next steps will appear here.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next steps',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.0.h),
        ...steps.map((step) {
          return Padding(
            padding: EdgeInsets.only(bottom: 0.8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 14.sp,
                  color: AppTheme.primaryLight,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    step,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/claude_revenue_optimization_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/opportunity_card_widget.dart';
import './widgets/revenue_roadmap_widget.dart';
import './widgets/coaching_chat_widget.dart';

class ClaudeRevenueOptimizationCoach extends StatefulWidget {
  const ClaudeRevenueOptimizationCoach({super.key});

  @override
  State<ClaudeRevenueOptimizationCoach> createState() =>
      _ClaudeRevenueOptimizationCoachState();
}

class _ClaudeRevenueOptimizationCoachState
    extends State<ClaudeRevenueOptimizationCoach>
    with SingleTickerProviderStateMixin {
  final ClaudeRevenueOptimizationService _optimizationService =
      ClaudeRevenueOptimizationService.instance;
  final AuthService _auth = AuthService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _opportunities = [];
  List<Map<String, dynamic>> _roadmapSteps = [];
  Map<String, dynamic> _coachingData = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOptimizationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOptimizationData() async {
    setState(() => _isLoading = true);

    try {
      final opportunities = await _optimizationService
          .getOptimizationRecommendations();
      final roadmap = await _optimizationService.getRevenueRoadmap();
      final coaching = await _optimizationService.getCoachingData();

      setState(() {
        _opportunities = opportunities;
        _roadmapSteps = roadmap;
        _coachingData = coaching;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load optimization data error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'ClaudeRevenueOptimizationCoach',
      onRetry: _loadOptimizationData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Revenue Coach',
          variant: CustomAppBarVariant.withBack,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadOptimizationData,
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : Column(
                children: [
                  _buildCoachGreeting(theme),
                  _buildTabBar(theme),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOpportunitiesTab(theme),
                        _buildRoadmapTab(theme),
                        _buildCoachingTab(theme),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Container(
          height: 15.h,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        SizedBox(height: 2.h),
        ...List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Container(
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoachGreeting(ThemeData theme) {
    final userName = _auth.currentUser?.userMetadata?['full_name'] ?? 'Creator';
    final totalPotential = _opportunities.fold<double>(
      0,
      (sum, opp) => sum + (opp['estimated_impact_usd'] as num? ?? 0),
    );

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withAlpha(179)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology, color: Colors.white, size: 8.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi $userName! 👋',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'I found ${_opportunities.length} opportunities to increase your earnings',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
                if (totalPotential > 0) ...[
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'Potential: +\$${totalPotential.toStringAsFixed(0)}/month',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: theme.textTheme.bodyMedium?.color,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Opportunities'),
          Tab(text: 'Roadmap'),
          Tab(text: 'Ask Coach'),
        ],
      ),
    );
  }

  Widget _buildOpportunitiesTab(ThemeData theme) {
    if (_opportunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 20.w, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'You\'re doing great!',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'No optimization opportunities right now',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOptimizationData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _opportunities.length,
        itemBuilder: (context, index) {
          return OpportunityCardWidget(
            opportunity: _opportunities[index],
            onImplement: () => _implementOpportunity(_opportunities[index]),
            onDismiss: () => _dismissOpportunity(_opportunities[index]),
          );
        },
      ),
    );
  }

  Widget _buildRoadmapTab(ThemeData theme) {
    return RevenueRoadmapWidget(
      roadmapSteps: _roadmapSteps,
      onRefresh: _loadOptimizationData,
    );
  }

  Widget _buildCoachingTab(ThemeData theme) {
    return CoachingChatWidget(
      coachingData: _coachingData,
      onSendMessage: _sendCoachingMessage,
    );
  }

  Future<void> _implementOpportunity(Map<String, dynamic> opportunity) async {
    try {
      await _optimizationService.implementRecommendation(
        opportunity['recommendation_id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Implementing: ${opportunity['title']}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadOptimizationData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to implement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _dismissOpportunity(Map<String, dynamic> opportunity) async {
    try {
      await _optimizationService.dismissRecommendation(
        opportunity['recommendation_id'],
      );

      await _loadOptimizationData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to dismiss: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendCoachingMessage(String message) async {
    try {
      await _optimizationService.askCoach(message);
      await _loadOptimizationData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
