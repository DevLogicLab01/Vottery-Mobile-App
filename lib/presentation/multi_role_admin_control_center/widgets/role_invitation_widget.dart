import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/multi_role_admin_service.dart';
import '../../../services/supabase_service.dart';

class RoleInvitationWidget extends StatefulWidget {
  const RoleInvitationWidget({super.key});

  @override
  State<RoleInvitationWidget> createState() => _RoleInvitationWidgetState();
}

class _RoleInvitationWidgetState extends State<RoleInvitationWidget> {
  final _adminService = MultiRoleAdminService();
  final _emailController = TextEditingController();

  String _selectedRole = 'admin';
  List<Map<String, dynamic>> _pendingInvitations = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadPendingInvitations();
  }

  Future<void> _loadPendingInvitations() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final invitations = await _adminService.getPendingInvitations(userId);
      setState(() {
        _pendingInvitations = invitations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading invitations: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendInvitation() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final result = await _adminService.inviteTeamMember(
        email: _emailController.text,
        role: _selectedRole,
        invitedBy: userId,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent successfully')),
        );
        _emailController.clear();
        _loadPendingInvitations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to send invitation'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInvitationForm(),
        SizedBox(height: 3.h),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPendingInvitationsList(),
        ),
      ],
    );
  }

  Widget _buildInvitationForm() {
    return Container(
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite Team Member',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter email address',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Role',
              prefixIcon: const Icon(Icons.admin_panel_settings),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: ['admin', 'moderator', 'editor', 'analyst']
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            },
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendInvitation,
              icon: _isSending
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSending ? 'Sending...' : 'Send Invitation',
                style: TextStyle(fontSize: 13.sp),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInvitationsList() {
    if (_pendingInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 48.sp, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No pending invitations',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      itemCount: _pendingInvitations.length,
      itemBuilder: (context, index) {
        final invitation = _pendingInvitations[index];
        return _buildInvitationCard(invitation);
      },
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final email = invitation['email'] ?? '';
    final role = invitation['invited_role'] ?? '';
    final createdAt = DateTime.parse(invitation['created_at']);
    final expiresAt = DateTime.parse(invitation['expires_at']);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.mail, color: Colors.blue.shade700),
        ),
        title: Text(
          email,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role: ${role.toUpperCase()}',
              style: TextStyle(fontSize: 11.sp),
            ),
            Text(
              'Expires: ${expiresAt.difference(DateTime.now()).inDays} days',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red),
          onPressed: () => _revokeInvitation(invitation['id']),
        ),
      ),
    );
  }

  Future<void> _revokeInvitation(String invitationId) async {
    try {
      final result = await _adminService.revokeInvitation(invitationId);
      if (result['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invitation revoked')));
        _loadPendingInvitations();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
