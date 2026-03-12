import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';

class WorkspaceSettingsWidget extends StatefulWidget {
  final String workspaceId;
  final VoidCallback onUpdate;

  const WorkspaceSettingsWidget({
    super.key,
    required this.workspaceId,
    required this.onUpdate,
  });

  @override
  State<WorkspaceSettingsWidget> createState() =>
      _WorkspaceSettingsWidgetState();
}

class _WorkspaceSettingsWidgetState extends State<WorkspaceSettingsWidget>
    with SingleTickerProviderStateMixin {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _workspace;
  List<Map<String, dynamic>> _members = [];
  final _inviteEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWorkspaceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkspaceData() async {
    setState(() => _isLoading = true);

    try {
      final workspace = await _client
          .from('workspaces')
          .select()
          .eq('id', widget.workspaceId)
          .single();

      final members = await _client
          .from('workspace_members')
          .select('*, user:user_profiles!user_id(*)')
          .eq('workspace_id', widget.workspaceId);

      setState(() {
        _workspace = workspace;
        _members = List<Map<String, dynamic>>.from(members);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load workspace data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _inviteMember() async {
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty) return;

    try {
      // In production, this would send an invitation email
      await _client.from('workspace_members').insert({
        'workspace_id': widget.workspaceId,
        'user_id': _auth.currentUser!.id, // Placeholder
        'role': 'viewer',
      });

      _inviteEmailController.clear();
      await _loadWorkspaceData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Invite member error: $e');
    }
  }

  Future<void> _removeMember(String memberId) async {
    try {
      await _client.from('workspace_members').delete().eq('id', memberId);

      await _loadWorkspaceData();
      widget.onUpdate();
    } catch (e) {
      debugPrint('Remove member error: $e');
    }
  }

  Future<void> _updateMemberRole(String memberId, String newRole) async {
    try {
      await _client
          .from('workspace_members')
          .update({'role': newRole})
          .eq('id', memberId);

      await _loadWorkspaceData();
    } catch (e) {
      debugPrint('Update member role error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 1.h),
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(77),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Workspace Settings',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(text: 'Members'),
                  Tab(text: 'Permissions'),
                ],
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMembersTab(scrollController, theme),
                          _buildPermissionsTab(scrollController, theme),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(ScrollController scrollController, ThemeData theme) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Invite Members',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inviteEmailController,
                decoration: InputDecoration(
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            ElevatedButton(
              onPressed: _inviteMember,
              child: const Text('Invite'),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Text(
          'Members (${_members.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ..._members.map((member) {
          final user = member['user'];
          final userName = user != null
              ? (user['full_name'] ?? user['email'] ?? 'Unknown')
              : 'Unknown';
          final role = member['role'] ?? 'viewer';

          return Card(
            margin: EdgeInsets.only(bottom: 2.h),
            child: ListTile(
              leading: CircleAvatar(child: Text(userName[0].toUpperCase())),
              title: Text(userName),
              subtitle: Text(role.toUpperCase()),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') {
                    _removeMember(member['id']);
                  } else {
                    _updateMemberRole(member['id'], value);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'owner',
                    child: Text('Change to Owner'),
                  ),
                  const PopupMenuItem(
                    value: 'editor',
                    child: Text('Change to Editor'),
                  ),
                  const PopupMenuItem(
                    value: 'commenter',
                    child: Text('Change to Commenter'),
                  ),
                  const PopupMenuItem(
                    value: 'viewer',
                    child: Text('Change to Viewer'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove Member'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPermissionsTab(
    ScrollController scrollController,
    ThemeData theme,
  ) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Role Permissions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        _buildPermissionCard(
          'Owner',
          'Full access to workspace settings, members, and content',
          Icons.admin_panel_settings,
          Colors.purple,
          theme,
        ),
        _buildPermissionCard(
          'Editor',
          'Can create and edit dashboards, annotations, and insights',
          Icons.edit,
          Colors.blue,
          theme,
        ),
        _buildPermissionCard(
          'Commenter',
          'Can add comments and annotations, but cannot edit content',
          Icons.comment,
          Colors.green,
          theme,
        ),
        _buildPermissionCard(
          'Viewer',
          'Read-only access to workspace content',
          Icons.visibility,
          Colors.grey,
          theme,
        ),
      ],
    );
  }

  Widget _buildPermissionCard(
    String role,
    String description,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          role,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(description),
      ),
    );
  }
}
