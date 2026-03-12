import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/multi_role_admin_service.dart';
import '../../services/supabase_service.dart';
import './widgets/permission_matrix_widget.dart';
import './widgets/role_activity_log_widget.dart';
import './widgets/role_assignment_widget.dart';
import './widgets/role_badge_widget.dart';
import './widgets/role_invitation_widget.dart';
import './widgets/team_analytics_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

class MultiRoleAdminControlCenter extends StatefulWidget {
  const MultiRoleAdminControlCenter({super.key});

  @override
  State<MultiRoleAdminControlCenter> createState() =>
      _MultiRoleAdminControlCenterState();
}

class _MultiRoleAdminControlCenterState
    extends State<MultiRoleAdminControlCenter> {
  final _adminService = MultiRoleAdminService();

  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _permissionMatrices = [];
  Map<String, dynamic> _roleAnalytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final dashboardData = await _adminService.getRoleDashboardData(userId);
      final matrices = await _adminService.getAllPermissionMatrices();
      final analytics = await _adminService.getRoleAnalytics();

      setState(() {
        _dashboardData = dashboardData;
        _permissionMatrices = matrices;
        _roleAnalytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'MultiRoleAdminControlCenter',
      onRetry: _loadDashboardData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Multi-Role Admin Control Center',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
            ),
          ],
        ),
        drawer: _buildNavigationDrawer(),
        body: _isLoading
            ? const SkeletonDashboard()
            : _dashboardData.isEmpty
            ? NoDataEmptyState(
                title: 'No Admin Roles',
                description: 'Admin roles and permissions will appear here.',
                onRefresh: _loadDashboardData,
              )
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserRoleBadge(),
                      SizedBox(height: 3.h),
                      _buildQuickStats(),
                      SizedBox(height: 3.h),
                      _buildSectionTabs(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildNavigationDrawer() {
    final userRole = _dashboardData['role'] ?? 'user';
    final colorCode = _dashboardData['color_code'] ?? 'gray';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getRoleColor(colorCode),
                  _getRoleColor(colorCode).withAlpha(179),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                RoleBadgeWidget(
                  role: userRole,
                  colorCode: colorCode,
                  size: 'large',
                ),
                SizedBox(height: 2.h),
                Text(
                  'Admin Control Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Team Management',
            onTap: () {},
          ),
          _buildDrawerItem(
            icon: Icons.security,
            title: 'Permissions',
            onTap: () {},
          ),
          _buildDrawerItem(
            icon: Icons.analytics,
            title: 'Analytics',
            onTap: () {},
          ),
          _buildDrawerItem(
            icon: Icons.history,
            title: 'Activity Logs',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20.sp),
      title: Text(title, style: TextStyle(fontSize: 14.sp)),
      onTap: onTap,
    );
  }

  Widget _buildUserRoleBadge() {
    final userRole = _dashboardData['role'] ?? 'user';
    final colorCode = _dashboardData['color_code'] ?? 'gray';
    final hierarchyLevel = _dashboardData['hierarchy_level'] ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRoleColor(colorCode).withAlpha(26),
            _getRoleColor(colorCode).withAlpha(13),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _getRoleColor(colorCode).withAlpha(77)),
      ),
      child: Row(
        children: [
          RoleBadgeWidget(role: userRole, colorCode: colorCode, size: 'medium'),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Role: ${userRole.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: _getRoleColor(colorCode),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Hierarchy Level: $hierarchyLevel',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(
            Icons.verified_user,
            color: _getRoleColor(colorCode),
            size: 24.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalMembers = _roleAnalytics['total_team_members'] ?? 0;
    final analytics = _roleAnalytics['analytics'] as List? ?? [];

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            label: 'Team Members',
            value: totalMembers.toString(),
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            icon: Icons.admin_panel_settings,
            label: 'Active Roles',
            value: analytics.length.toString(),
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs() {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Role Assignment'),
              Tab(text: 'Permission Matrix'),
              Tab(text: 'Team Analytics'),
              Tab(text: 'Invitations'),
              Tab(text: 'Activity Logs'),
            ],
          ),
          SizedBox(
            height: 60.h,
            child: TabBarView(
              children: [
                RoleAssignmentWidget(permissionMatrices: _permissionMatrices),
                PermissionMatrixWidget(permissionMatrices: _permissionMatrices),
                TeamAnalyticsWidget(roleAnalytics: _roleAnalytics),
                const RoleInvitationWidget(),
                const RoleActivityLogWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String colorCode) {
    switch (colorCode) {
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.amber;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
