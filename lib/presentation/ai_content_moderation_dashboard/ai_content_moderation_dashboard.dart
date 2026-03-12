import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/content_moderation_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/moderation_queue_card_widget.dart';
import './widgets/moderation_stats_overview_widget.dart';
import './widgets/appeals_list_widget.dart';
import './widgets/analytics_dashboard_widget.dart';

class AIContentModerationDashboard extends StatefulWidget {
  const AIContentModerationDashboard({super.key});

  @override
  State<AIContentModerationDashboard> createState() =>
      _AIContentModerationDashboardState();
}

class _AIContentModerationDashboardState
    extends State<AIContentModerationDashboard>
    with SingleTickerProviderStateMixin {
  final ContentModerationService _moderationService =
      ContentModerationService.instance;
  final _client = SupabaseService.instance.client;
  late TabController _tabController;

  bool _isLoading = false;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _moderationService.getModerationStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load stats error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeSubscriptions() {
    _client.from('moderation_log').stream(primaryKey: ['log_id']).listen((_) {
      _loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'AIContentModerationDashboard',
      onRetry: _loadStats,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'AI Content Moderation',
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
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'settings',
                  color: theme.appBarTheme.foregroundColor!,
                  size: 24,
                ),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 8)
            : Column(
                children: [
                  ModerationStatsOverviewWidget(stats: _stats),
                  TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.disabledColor,
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Queue'),
                      Tab(text: 'Appeals'),
                      Tab(text: 'Analytics'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildModerationQueue(),
                        const AppealsListWidget(),
                        const AnalyticsDashboardWidget(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildModerationQueue() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _client
          .from('moderation_log')
          .stream(primaryKey: ['log_id'])
          .eq('action_taken', 'flagged')
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No flagged content', 'verified_user');
        }

        return RefreshIndicator(
          onRefresh: _loadStats,
          child: ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return ModerationQueueCardWidget(
                item: snapshot.data![index],
                onApprove: () => _handleApprove(snapshot.data![index]),
                onRemove: () => _handleRemove(snapshot.data![index]),
                onEscalate: () => _handleEscalate(snapshot.data![index]),
              );
            },
          ),
        );
      },
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

  Future<void> _handleApprove(Map<String, dynamic> item) async {
    try {
      await _client
          .from('moderation_log')
          .update({'action_taken': 'approved'})
          .eq('log_id', item['log_id']);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Content approved')));
      }
    } catch (e) {
      debugPrint('Approve error: $e');
    }
  }

  Future<void> _handleRemove(Map<String, dynamic> item) async {
    try {
      await _client
          .from('moderation_log')
          .update({'action_taken': 'removed'})
          .eq('log_id', item['log_id']);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Content removed')));
      }
    } catch (e) {
      debugPrint('Remove error: $e');
    }
  }

  Future<void> _handleEscalate(Map<String, dynamic> item) async {
    try {
      await _client
          .from('moderation_log')
          .update({'action_taken': 'escalated'})
          .eq('log_id', item['log_id']);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Content escalated')));
      }
    } catch (e) {
      debugPrint('Escalate error: $e');
    }
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moderation Settings'),
        content: const Text('Configure auto-moderation thresholds'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
