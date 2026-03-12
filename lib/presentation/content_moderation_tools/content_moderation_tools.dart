import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/claude_service.dart';
import '../../services/multi_ai_orchestration_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/flagged_content_card_widget.dart';
import './widgets/moderator_queue_widget.dart';
import './widgets/appeal_workflow_widget.dart';
import './widgets/moderation_stats_widget.dart';
import './widgets/ai_moderation_panel_widget.dart';
import './widgets/bulk_moderation_widget.dart';

/// Content Moderation Tools Screen
/// Comprehensive content oversight with AI-assisted flagging dashboard,
/// moderator queue management, and structured appeal workflows
class ContentModerationTools extends StatefulWidget {
  const ContentModerationTools({super.key});

  @override
  State<ContentModerationTools> createState() => _ContentModerationToolsState();
}

class _ContentModerationToolsState extends State<ContentModerationTools>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClaudeService _claudeService = ClaudeService.instance;
  final MultiAIOrchestrationService _orchestration =
      MultiAIOrchestrationService.instance;
  final _client = SupabaseService.instance.client;

  bool _isLoading = false;
  int _pendingQueueCount = 0;
  int _appealCount = 0;
  int _flaggedCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadModerationStats();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadModerationStats() async {
    setState(() => _isLoading = true);
    try {
      final flaggedResponse = await _client
          .from('content_moderation_logs')
          .select('id')
          .eq('moderation_action', 'flagged')
          .isFilter('reviewed_at', null);

      final pendingResponse = await _client
          .from('content_moderation_logs')
          .select('id')
          .eq('moderation_action', 'pending_review')
          .isFilter('reviewed_at', null);

      setState(() {
        _flaggedCount = (flaggedResponse as List).length;
        _pendingQueueCount = (pendingResponse as List).length;
        _appealCount = 0; // TODO: Add appeals table query
      });
    } catch (e) {
      debugPrint('Load moderation stats error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeSubscriptions() {
    _client.from('content_moderation_logs').stream(primaryKey: ['id']).listen((
      data,
    ) {
      _loadModerationStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'ContentModerationTools',
      onRetry: _loadModerationStats,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Content Moderation',
            variant: CustomAppBarVariant.standard,
            leading: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: theme.appBarTheme.foregroundColor!,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'notifications',
                      color: theme.appBarTheme.foregroundColor!,
                      size: 24,
                    ),
                    onPressed: () => _showEmergencyAlerts(context),
                  ),
                  if (_pendingQueueCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _pendingQueueCount.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'settings',
                  color: theme.appBarTheme.foregroundColor!,
                  size: 24,
                ),
                onPressed: () => _showModerationSettings(context),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 8)
            : RefreshIndicator(
                onRefresh: _loadModerationStats,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _client
                      .from('content_moderation_logs')
                      .stream(primaryKey: ['id'])
                      .eq('moderation_action', 'flagged')
                      .order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState(
                        'No flagged content',
                        'verified_user',
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(4.w),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return FlaggedContentCardWidget(
                          content: snapshot.data![index],
                          onApprove: () =>
                              _handleApprove(snapshot.data![index]['id']),
                          onRemove: () =>
                              _handleRemove(snapshot.data![index]['id']),
                          onEscalate: () =>
                              _handleEscalate(snapshot.data![index]['id']),
                        );
                      },
                    );
                  },
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showBulkModerationModal(context),
          icon: CustomIconWidget(
            iconName: 'checklist',
            color: theme.floatingActionButtonTheme.foregroundColor!,
            size: 24,
          ),
          label: Text(
            'Bulk Actions',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.floatingActionButtonTheme.foregroundColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ModerationStatsWidget(
              title: 'Flagged',
              count: _flaggedCount,
              iconName: 'flag',
              color: const Color(0xFFF59E0B),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: ModerationStatsWidget(
              title: 'Queue',
              count: _pendingQueueCount,
              iconName: 'pending',
              color: const Color(0xFF3B82F6),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: ModerationStatsWidget(
              title: 'Appeals',
              count: _appealCount,
              iconName: 'gavel',
              color: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.textTheme.bodyMedium?.color,
        indicatorColor: theme.colorScheme.primary,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Flagged Content'),
          Tab(text: 'Moderator Queue'),
          Tab(text: 'Appeals'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildFlaggedContentTab() {
    return RefreshIndicator(
      onRefresh: _loadModerationStats,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _client
            .from('content_moderation_logs')
            .stream(primaryKey: ['id'])
            .eq('moderation_action', 'flagged')
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState('No flagged content', 'verified_user');
          }

          return ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return FlaggedContentCardWidget(
                content: snapshot.data![index],
                onApprove: () => _handleApprove(snapshot.data![index]['id']),
                onRemove: () => _handleRemove(snapshot.data![index]['id']),
                onEscalate: () => _handleEscalate(snapshot.data![index]['id']),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModeratorQueueTab() {
    return ModeratorQueueWidget(onItemProcessed: _loadModerationStats);
  }

  Widget _buildAppealManagementTab() {
    return AppealWorkflowWidget(onAppealResolved: _loadModerationStats);
  }

  Widget _buildModerationAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AIModerationPanelWidget(),
          SizedBox(height: 2.h),
          _buildDecisionPatternsCard(),
          SizedBox(height: 2.h),
          _buildAccuracyMetricsCard(),
        ],
      ),
    );
  }

  Widget _buildDecisionPatternsCard() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'analytics',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Decision Patterns',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildPatternRow('Approved', 67, const Color(0xFF10B981)),
          SizedBox(height: 1.h),
          _buildPatternRow('Removed', 23, const Color(0xFFEF4444)),
          SizedBox(height: 1.h),
          _buildPatternRow('Escalated', 10, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildPatternRow(String label, int percentage, Color color) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          '$percentage%',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyMetricsCard() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'verified',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Accuracy Metrics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem('AI Accuracy', '94.2%', Colors.green),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Human Override',
                  '5.8%',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, String iconName) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: theme.disabledColor,
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(String contentId) async {
    try {
      await _client
          .from('content_moderation_logs')
          .update({
            'moderation_action': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contentId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Content approved')));
      }
    } catch (e) {
      debugPrint('Approve content error: $e');
    }
  }

  Future<void> _handleRemove(String contentId) async {
    try {
      await _client
          .from('content_moderation_logs')
          .update({
            'moderation_action': 'removed',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contentId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Content removed')));
      }
    } catch (e) {
      debugPrint('Remove content error: $e');
    }
  }

  Future<void> _handleEscalate(String contentId) async {
    try {
      await _client
          .from('content_moderation_logs')
          .update({
            'moderation_action': 'escalated',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content escalated to senior moderator'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Escalate content error: $e');
    }
  }

  void _showEmergencyAlerts(BuildContext context) {
    // TODO: Implement emergency alerts modal
  }

  void _showModerationSettings(BuildContext context) {
    // TODO: Implement moderation settings
  }

  void _showBulkModerationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          BulkModerationWidget(onComplete: _loadModerationStats),
    );
  }
}
