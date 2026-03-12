import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/moderation_shared_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Content Moderation Control Center – Web parity: Dashboard, Flagged Content,
/// Moderator Queue, Violations, Actions, Appeals (content_flags, content_appeals).
class ContentModerationControlCenterScreen extends StatefulWidget {
  const ContentModerationControlCenterScreen({super.key});

  @override
  State<ContentModerationControlCenterScreen> createState() =>
      _ContentModerationControlCenterScreenState();
}

class _ContentModerationControlCenterScreenState
    extends State<ContentModerationControlCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ModerationSharedService _mod = ModerationSharedService.instance;

  bool _loading = true;
  bool _refreshing = false;
  Map<String, dynamic> _analytics = {};
  Map<String, dynamic> _modelPerformance = {};
  List<Map<String, dynamic>> _flaggedContent = [];
  List<Map<String, dynamic>> _queueContent = [];
  List<Map<String, dynamic>> _violations = [];
  List<Map<String, dynamic>> _actions = [];
  List<Map<String, dynamic>> _appeals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      await Future.wait([
        _loadAnalytics(),
        _loadFlagged(),
        _loadViolations(),
        _loadActions(),
        _loadPerformance(),
        _loadAppeals(),
      ]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    final a = await _mod.getContentAnalytics();
    if (mounted) setState(() => _analytics = a);
  }

  Future<void> _loadFlagged() async {
    final list = await _mod.getFlaggedContent();
    if (mounted) {
      setState(() {
        _flaggedContent = list;
        _queueContent = list
            .where((f) =>
                f['status'] == 'pending_review' || f['status'] == 'under_review')
            .toList();
      });
    }
  }

  Future<void> _loadViolations() async {
    final list = await _mod.getViolationsByCategory();
    if (mounted) setState(() => _violations = list);
  }

  Future<void> _loadActions() async {
    final list = await _mod.getModerationActions();
    if (mounted) setState(() => _actions = list);
  }

  Future<void> _loadPerformance() async {
    final p = await _mod.getModelPerformance();
    if (mounted) setState(() => _modelPerformance = p);
  }

  Future<void> _loadAppeals() async {
    final list = await _mod.getAppeals();
    if (mounted) setState(() => _appeals = list);
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _loadAll();
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _onModerationAction(String flagId, String action) async {
    final ok = await _mod.performModerationAction(
      flagId,
      action,
      'Moderator review',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Action applied' : 'Action failed'),
        ),
      );
      if (ok) await _loadAll();
    }
  }

  Future<void> _onResolveAppeal(String appealId, String outcome) async {
    final ok = await _mod.resolveAppeal(appealId, outcome);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Appeal resolved' : 'Failed'),
        ),
      );
      if (ok) await _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'ContentModerationControlCenter',
      onRetry: _loadAll,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Content Moderation Control Center'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: _refreshing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _refreshing ? null : _refresh,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              const Tab(text: 'Dashboard'),
              Tab(
                text: 'Flagged',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Flagged'),
                    if ((_analytics['pendingReview'] as int? ?? 0) > 0) ...[
                      SizedBox(width: 1.w),
                      _buildBadge(_analytics['pendingReview'] as int),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Queue'),
              const Tab(text: 'Violations'),
              const Tab(text: 'Actions'),
              Tab(
                text: 'Appeals',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Appeals'),
                    if (_appeals.any((a) => a['status'] == 'pending')) ...[
                      SizedBox(width: 1.w),
                      _buildBadge(
                          _appeals.where((a) => a['status'] == 'pending').length),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _loading
            ? const SkeletonList(itemCount: 8)
            : RefreshIndicator(
                onRefresh: _refresh,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(theme),
                    _buildFlaggedList(_flaggedContent, theme),
                    _buildFlaggedList(_queueContent, theme),
                    _buildViolationsTab(theme),
                    _buildActionsTab(theme),
                    _buildAppealsTab(theme),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: const BoxDecoration(
        color: Color(0xFFEF4444),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDashboardTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _statCard(
                theme,
                'Flagged',
                _analytics['flaggedContent']?.toString() ?? '0',
                Icons.flag,
                Colors.orange,
              ),
              SizedBox(width: 2.w),
              _statCard(
                theme,
                'Pending',
                _analytics['pendingReview']?.toString() ?? '0',
                Icons.pending_actions,
                Colors.blue,
              ),
              SizedBox(width: 2.w),
              _statCard(
                theme,
                'Appeals',
                _appeals.where((a) => a['status'] == 'pending').length.toString(),
                Icons.gavel,
                Colors.purple,
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'AI Model Performance',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _statCard(
                theme,
                'Accuracy',
                '${(_modelPerformance['accuracy'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                Icons.check_circle,
                Colors.green,
              ),
              SizedBox(width: 2.w),
              _statCard(
                theme,
                'Precision',
                '${(_modelPerformance['precision'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                Icons.precision_manufacturing,
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 1.h),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlaggedList(
    List<Map<String, dynamic>> list,
    ThemeData theme,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(iconName: 'verified_user', size: 48, color: theme.disabledColor),
            SizedBox(height: 2.h),
            Text(
              'No items',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final item = list[i];
        final id = item['id'] as String?;
        final status = item['status'] as String? ?? '';
        final severity = item['severity'] as String? ?? '';
        final violationType = item['violationType'] as String? ?? '';
        final content = item['content'] as String? ?? '';
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: ListTile(
            title: Text(
              violationType.toString().replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              content.toString().length > 80
                  ? '${content.toString().substring(0, 80)}...'
                  : content.toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == 'pending_review' || status == 'under_review') ...[
                  TextButton(
                    onPressed: () => _onModerationAction(id!, 'approve'),
                    child: const Text('Approve'),
                  ),
                  TextButton(
                    onPressed: () => _onModerationAction(id!, 'remove'),
                    child: const Text('Remove'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViolationsTab(ThemeData theme) {
    if (_violations.isEmpty) {
      return Center(
        child: Text(
          'No violation data',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _violations.length,
      itemBuilder: (context, i) {
        final v = _violations[i];
        return ListTile(
          title: Text(v['category'] as String? ?? ''),
          trailing: Text(
            '${v['count']}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionsTab(ThemeData theme) {
    if (_actions.isEmpty) {
      return Center(
        child: Text(
          'No actions yet',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _actions.length,
      itemBuilder: (context, i) {
        final a = _actions[i];
        return ListTile(
          title: Text(a['action'] as String? ?? ''),
          trailing: Text(
            '${a['count']} (${a['percentage']}%)',
            style: theme.textTheme.bodyMedium,
          ),
        );
      },
    );
  }

  Widget _buildAppealsTab(ThemeData theme) {
    if (_appeals.isEmpty) {
      return Center(
        child: Text(
          'No appeals',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _appeals.length,
      itemBuilder: (context, i) {
        final a = _appeals[i];
        final id = a['id'] as String?;
        final status = a['status'] as String? ?? '';
        final reason = a['reason'] as String? ?? '';
        final appellantName = a['appellantName'] as String? ?? 'Unknown';
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: ListTile(
            title: Text(appellantName),
            subtitle: Text(reason),
            trailing: status == 'pending'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _onResolveAppeal(id!, 'overturned'),
                        child: const Text('Overturn'),
                      ),
                      TextButton(
                        onPressed: () => _onResolveAppeal(id!, 'dismissed'),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  )
                : Text(status),
          ),
        );
      },
    );
  }
}
