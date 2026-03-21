import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/carousel_moderation_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Carousel Content Moderation Automation Center
/// AI-powered content filtering with Claude-based violation detection
class CarouselContentModerationAutomationCenter extends StatefulWidget {
  const CarouselContentModerationAutomationCenter({super.key});

  @override
  State<CarouselContentModerationAutomationCenter> createState() =>
      _CarouselContentModerationAutomationCenterState();
}

class _CarouselContentModerationAutomationCenterState
    extends State<CarouselContentModerationAutomationCenter>
    with SingleTickerProviderStateMixin {
  final CarouselModerationService _moderationService =
      CarouselModerationService.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _pendingQueue = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final queue = await _moderationService.getModerationQueue();
    final stats = await _moderationService.getModerationStatistics();

    List<Map<String, dynamic>> actions = [];
    try {
      final raw = await SupabaseService.instance.client
          .from('moderation_actions')
          .select('id,action,reason,created_at,flag_id,moderator_id')
          .order('created_at', ascending: false)
          .limit(50);
      actions = List<Map<String, dynamic>>.from(raw as List);
    } catch (e) {
      debugPrint('Load moderation_actions error: $e');
    }

    if (mounted) {
      setState(() {
        _pendingQueue = queue;
        _automatedActions = actions;
        _statistics = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CarouselContentModerationAutomationCenter',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: CustomAppBar(
          title: 'Content Moderation',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: AppThemeColors.electricGold),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: Column(
                  children: [
                    _buildModerationStatusOverview(),
                    Container(
                      color: AppTheme.surfaceDark,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppThemeColors.electricGold,
                        unselectedLabelColor: AppTheme.textSecondaryDark,
                        indicatorColor: AppThemeColors.electricGold,
                        tabs: const [
                          Tab(text: 'Pending Reviews'),
                          Tab(text: 'Automated Actions'),
                          Tab(text: 'Analytics'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPendingReviewsTab(),
                          _buildAutomatedActionsTab(),
                          _buildAnalyticsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildModerationStatusOverview() {
    final totalReviewed = _statistics['total_reviewed'] ?? 0;
    final autoRemoved = _statistics['auto_removed'] ?? 0;
    final avgSafetyScore = _statistics['avg_safety_score'] ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withAlpha(51),
            AppTheme.surfaceDark,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Pending',
              _pendingQueue.length.toString(),
              Icons.pending_actions,
              Colors.orange,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildStatCard(
              'Reviewed',
              totalReviewed.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildStatCard(
              'Auto-Removed',
              autoRemoved.toString(),
              Icons.block,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReviewsTab() {
    if (_pendingQueue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No pending reviews',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _pendingQueue.length,
      itemBuilder: (context, index) {
        final item = _pendingQueue[index];
        final moderation = item['moderation'];
        return _buildModerationCard(item, moderation);
      },
    );
  }

  Widget _buildModerationCard(
    Map<String, dynamic> queueItem,
    Map<String, dynamic> moderation,
  ) {
    final violations = List<Map<String, dynamic>>.from(moderation['violations'] ?? []);
    final safetyScore = moderation['overall_safety_score'] ?? 100;
    final qualityScore = moderation['content_quality_score'] ?? 70;

    return Card(
      color: AppTheme.surfaceDark,
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    moderation['title'] ?? 'Untitled Content',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildPriorityBadge(queueItem['priority']),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              moderation['content_type'] ?? 'Unknown',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildScoreIndicator(
                    'Safety',
                    safetyScore,
                    safetyScore >= 70 ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildScoreIndicator(
                    'Quality',
                    qualityScore,
                    qualityScore >= 60 ? Colors.blue : Colors.orange,
                  ),
                ),
              ],
            ),
            if (violations.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                'Violations (${violations.length})',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 1.h),
              ...violations.take(3).map((violation) => Padding(
                    padding: EdgeInsets.only(bottom: 0.5.h),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 16),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            '${violation['category']} (${violation['severity']})',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppTheme.textSecondaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveContent(queueItem['moderation_id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _removeContent(queueItem['moderation_id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'critical':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.yellow;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(String label, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppTheme.textSecondaryDark,
          ),
        ),
        SizedBox(height: 0.5.h),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: color.withAlpha(51),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAutomatedActionsTab() {
    if (_automatedActions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        children: [
          Text(
            'No moderation actions recorded yet.',
            style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondaryDark),
          ),
          SizedBox(height: 2.h),
          TextButton.icon(
            onPressed: () => Navigator.of(context, rootNavigator: true)
                .pushNamed(AppRoutes.contentModerationControlCenter),
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Open moderation control center'),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      itemCount: _automatedActions.length,
      separatorBuilder: (_, __) => Divider(color: AppTheme.textSecondaryDark.withValues(alpha: 0.2)),
      itemBuilder: (context, i) {
        final row = _automatedActions[i];
        return ListTile(
          title: Text(
            row['action']?.toString() ?? 'action',
            style: TextStyle(
              color: AppTheme.textPrimaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${row['created_at'] ?? ''}\n${row['reason'] ?? ''}',
            style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryDark),
          ),
          isThreeLine: true,
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    final avgSafetyScore = _statistics['avg_safety_score'] ?? 0;
    final avgQualityScore = _statistics['avg_quality_score'] ?? 0;
    final falsePositiveRate = _statistics['false_positive_rate'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moderation Performance',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          SizedBox(height: 2.h),
          _buildAnalyticsCard(
            'Average Safety Score',
            avgSafetyScore.toString(),
            Icons.security,
            Colors.green,
          ),
          SizedBox(height: 2.h),
          _buildAnalyticsCard(
            'Average Quality Score',
            avgQualityScore.toString(),
            Icons.star,
            Colors.blue,
          ),
          SizedBox(height: 2.h),
          _buildAnalyticsCard(
            'False Positive Rate',
            '${falsePositiveRate.toStringAsFixed(1)}%',
            Icons.error_outline,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveContent(String moderationId) async {
    await _moderationService.approveContent(moderationId);
    _loadData();
  }

  Future<void> _removeContent(String moderationId) async {
    await _moderationService.removeContent(
      moderationId,
      'Removed by moderator',
    );
    _loadData();
  }
}