import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/multi_role_admin_service.dart';
import './role_badge_widget.dart';

class RoleAssignmentWidget extends StatefulWidget {
  final List<Map<String, dynamic>> permissionMatrices;

  const RoleAssignmentWidget({super.key, required this.permissionMatrices});

  @override
  State<RoleAssignmentWidget> createState() => _RoleAssignmentWidgetState();
}

class _RoleAssignmentWidgetState extends State<RoleAssignmentWidget> {
  final _adminService = MultiRoleAdminService();
  final _searchController = TextEditingController();

  String _selectedRole = 'admin';
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    setState(() => _isLoading = true);

    try {
      final members = await _adminService.getTeamMembersByRole(_selectedRole);
      setState(() {
        _teamMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading team members: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRoleSelector(),
        SizedBox(height: 2.h),
        _buildSearchBar(),
        SizedBox(height: 2.h),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _teamMembers.isEmpty
              ? _buildEmptyState()
              : _buildTeamMembersList(),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: EdgeInsets.all(3.w),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedRole,
        decoration: InputDecoration(
          labelText: 'Select Role',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          prefixIcon: const Icon(Icons.admin_panel_settings),
        ),
        items: widget.permissionMatrices.map((matrix) {
          final role = matrix['role'] ?? '';
          final colorCode = matrix['color_code'] ?? 'gray';
          return DropdownMenuItem<String>(
            value: role,
            child: RoleBadgeWidget(
              role: role,
              colorCode: colorCode,
              size: 'small',
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedRole = value);
            _loadTeamMembers();
          }
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search team members...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildTeamMembersList() {
    final filteredMembers = _teamMembers.where((member) {
      final name = member['full_name']?.toString().toLowerCase() ?? '';
      final email = member['email']?.toString().toLowerCase() ?? '';
      final query = _searchController.text.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        return _buildTeamMemberCard(member);
      },
    );
  }

  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    final name = member['full_name'] ?? 'Unknown';
    final email = member['email'] ?? '';
    final avatarUrl = member['avatar_url'];

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null ? Text(name[0].toUpperCase()) : null,
        ),
        title: Text(
          name,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          email,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
        trailing: RoleBadgeWidget(
          role: _selectedRole,
          colorCode: _getRoleColorCode(_selectedRole),
          size: 'small',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 48.sp, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'No team members with this role',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getRoleColorCode(String role) {
    final matrix = widget.permissionMatrices.firstWhere(
      (m) => m['role'] == role,
      orElse: () => {'color_code': 'gray'},
    );
    return matrix['color_code'] ?? 'gray';
  }
}
