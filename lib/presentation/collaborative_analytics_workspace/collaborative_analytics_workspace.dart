import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/workspace_card_widget.dart';
import './widgets/create_workspace_dialog_widget.dart';
import './widgets/dashboard_card_widget.dart';
import './widgets/decision_log_widget.dart';
import './widgets/insight_library_widget.dart';
import './widgets/workspace_activity_feed_widget.dart';
import './widgets/workspace_settings_widget.dart';

class CollaborativeAnalyticsWorkspace extends StatefulWidget {
  const CollaborativeAnalyticsWorkspace({super.key});

  @override
  State<CollaborativeAnalyticsWorkspace> createState() =>
      _CollaborativeAnalyticsWorkspaceState();
}

class _CollaborativeAnalyticsWorkspaceState
    extends State<CollaborativeAnalyticsWorkspace>
    with SingleTickerProviderStateMixin {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _workspaces = [];
  String? _selectedWorkspaceId;
  List<Map<String, dynamic>> _dashboards = [];
  StreamSubscription? _activitySubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadWorkspaces();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadWorkspaces() async {
    setState(() => _isLoading = true);

    try {
      if (!_auth.isAuthenticated) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await _client
          .from('workspaces')
          .select()
          .or(
            'owner_id.eq.${_auth.currentUser!.id},id.in.(select workspace_id from workspace_members where user_id=${_auth.currentUser!.id})',
          )
          .order('last_activity_at', ascending: false);

      setState(() {
        _workspaces = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load workspaces error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboards(String workspaceId) async {
    try {
      final response = await _client
          .from('shared_dashboards')
          .select('*, creator:user_profiles!created_by(*)')
          .eq('workspace_id', workspaceId)
          .order('last_modified_at', ascending: false);

      setState(() {
        _dashboards = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Load dashboards error: $e');
    }
  }

  void _selectWorkspace(String workspaceId) {
    setState(() => _selectedWorkspaceId = workspaceId);
    _loadDashboards(workspaceId);
    _subscribeToWorkspaceActivity(workspaceId);
  }

  void _subscribeToWorkspaceActivity(String workspaceId) {
    _activitySubscription?.cancel();

    final channel = _client.channel('workspace:$workspaceId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'workspace_activity',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'workspace_id',
            value: workspaceId,
          ),
          callback: (payload) {
            // Refresh activity feed
            setState(() {});
          },
        )
        .subscribe();
  }

  Future<void> _showCreateWorkspaceDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateWorkspaceDialogWidget(),
    );

    if (result != null) {
      await _createWorkspace(result);
    }
  }

  Future<void> _createWorkspace(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('workspaces')
          .insert({
            'name': data['name'],
            'description': data['description'],
            'icon': data['icon'] ?? '📊',
            'owner_id': _auth.currentUser!.id,
          })
          .select()
          .single();

      await _loadWorkspaces();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workspace created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Create workspace error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleStarWorkspace(String workspaceId, bool isStarred) async {
    try {
      await _client
          .from('workspaces')
          .update({'is_starred': !isStarred})
          .eq('id', workspaceId);

      await _loadWorkspaces();
    } catch (e) {
      debugPrint('Toggle star error: $e');
    }
  }

  void _showWorkspaceSettings() {
    if (_selectedWorkspaceId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkspaceSettingsWidget(
        workspaceId: _selectedWorkspaceId!,
        onUpdate: () => _loadWorkspaces(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'CollaborativeAnalyticsWorkspace',
      onRetry: _loadWorkspaces,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: _selectedWorkspaceId == null
                ? 'Workspaces'
                : _workspaces.firstWhere(
                        (w) => w['id'] == _selectedWorkspaceId,
                        orElse: () => {'name': 'Workspace'},
                      )['name'] ??
                      'Workspace',
            variant: CustomAppBarVariant.standard,
            leading: _selectedWorkspaceId != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() => _selectedWorkspaceId = null);
                      _activitySubscription?.cancel();
                    },
                  )
                : null,
            actions: [
              if (_selectedWorkspaceId != null)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _showWorkspaceSettings,
                ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : _selectedWorkspaceId == null
            ? _buildWorkspaceDirectory(theme)
            : _buildWorkspaceDetail(theme),
        floatingActionButton: _selectedWorkspaceId == null
            ? FloatingActionButton.extended(
                onPressed: _showCreateWorkspaceDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Workspace'),
              )
            : null,
      ),
    );
  }

  Widget _buildWorkspaceDirectory(ThemeData theme) {
    if (_workspaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspaces_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text('No Workspaces Yet', style: theme.textTheme.titleLarge),
            SizedBox(height: 1.h),
            Text(
              'Create a workspace to start collaborating',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWorkspaces,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _workspaces.length,
        itemBuilder: (context, index) {
          final workspace = _workspaces[index];
          return WorkspaceCardWidget(
            workspace: workspace,
            onTap: () => _selectWorkspace(workspace['id']),
            onToggleStar: () => _toggleStarWorkspace(
              workspace['id'],
              workspace['is_starred'] ?? false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkspaceDetail(ThemeData theme) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Dashboards'),
            Tab(text: 'Decisions'),
            Tab(text: 'Insights'),
            Tab(text: 'Activity'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardsTab(theme),
              DecisionLogWidget(workspaceId: _selectedWorkspaceId!),
              InsightLibraryWidget(workspaceId: _selectedWorkspaceId!),
              WorkspaceActivityFeedWidget(workspaceId: _selectedWorkspaceId!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardsTab(ThemeData theme) {
    if (_dashboards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text('No Dashboards Yet', style: theme.textTheme.titleLarge),
            SizedBox(height: 1.h),
            Text(
              'Create a dashboard to start analyzing',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _dashboards.length,
      itemBuilder: (context, index) {
        final dashboard = _dashboards[index];
        return DashboardCardWidget(
          dashboard: dashboard,
          onTap: () {
            // Navigate to dashboard detail
          },
        );
      },
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;

  const SkeletonList({super.key, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 2.h),
          child: SkeletonCard(height: 15.h, width: double.infinity),
        );
      },
    );
  }
}
