import './enhanced_notification_service.dart';
import './supabase_service.dart';

class MultiRoleAdminService {
  static final MultiRoleAdminService _instance =
      MultiRoleAdminService._internal();
  factory MultiRoleAdminService() => _instance;
  MultiRoleAdminService._internal();

  final _supabase = SupabaseService.instance.client;
  final _notificationService = EnhancedNotificationService.instance;

  // Role hierarchy levels
  static const Map<String, int> roleHierarchy = {
    'manager': 100,
    'admin': 90,
    'moderator': 70,
    'auditor': 60,
    'editor': 50,
    'advertiser': 40,
    'analyst': 30,
    'user': 0,
  };

  // Role color codes for UI badges
  static const Map<String, String> roleColors = {
    'manager': 'purple',
    'admin': 'red',
    'moderator': 'blue',
    'auditor': 'green',
    'editor': 'orange',
    'advertiser': 'yellow',
    'analyst': 'teal',
    'user': 'gray',
  };

  /// Get all permission matrices
  Future<List<Map<String, dynamic>>> getAllPermissionMatrices() async {
    try {
      final response = await _supabase
          .from('permission_matrices')
          .select('*')
          .order('hierarchy_level', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching permission matrices: $e');
      return [];
    }
  }

  /// Get permissions for specific role
  Future<Map<String, dynamic>?> getRolePermissions(String role) async {
    try {
      final response = await _supabase
          .from('permission_matrices')
          .select('permissions')
          .eq('role', role)
          .single();

      return response['permissions'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching role permissions: $e');
      return null;
    }
  }

  /// Check if user has specific permission
  Future<bool> checkUserPermission(String userId, String permission) async {
    try {
      final response = await _supabase.rpc(
        'check_user_permission',
        params: {'p_user_id': userId, 'p_permission': permission},
      );

      return response ?? false;
    } catch (e) {
      print('Error checking user permission: $e');
      return false;
    }
  }

  /// Assign role to user
  Future<Map<String, dynamic>> assignRole({
    required String userId,
    required String role,
    required String assignedBy,
    String? assignmentReason,
    DateTime? expiresAt,
  }) async {
    try {
      // Check if assigner has permission
      final assignerRole = await _getUserRole(assignedBy);
      final targetHierarchy = roleHierarchy[role] ?? 0;
      final assignerHierarchy = roleHierarchy[assignerRole] ?? 0;

      if (assignerHierarchy <= targetHierarchy) {
        return {
          'success': false,
          'error': 'You cannot assign a role equal to or higher than your own',
        };
      }

      // Update user role
      await _supabase
          .from('user_profiles')
          .update({'role': role})
          .eq('id', userId);

      // Record role assignment
      await _supabase.from('role_assignments').insert({
        'user_id': userId,
        'assigned_role': role,
        'assigned_by': assignedBy,
        'assignment_reason': assignmentReason,
        'expires_at': expiresAt?.toIso8601String(),
      });

      // Log activity
      await _logRoleActivity(
        actorId: assignedBy,
        actionType: 'role_assignment',
        targetResource: 'user',
        targetId: userId,
        actionDetails: {'assigned_role': role, 'reason': assignmentReason},
      );

      // Notify user
      await _notificationService.sendNotification(
        userId: userId,
        title: 'Role Assignment',
        body: 'You have been assigned the role: $role',
        category: 'role_management',
        priority: 'high',
      );

      return {'success': true, 'message': 'Role assigned successfully'};
    } catch (e) {
      print('Error assigning role: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Invite team member with role
  Future<Map<String, dynamic>> inviteTeamMember({
    required String email,
    required String role,
    required String invitedBy,
  }) async {
    try {
      final invitationToken = _generateInvitationToken();
      final expiresAt = DateTime.now().add(const Duration(days: 7));

      final response = await _supabase
          .from('role_invitations')
          .insert({
            'email': email,
            'invited_role': role,
            'invited_by': invitedBy,
            'invitation_token': invitationToken,
            'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();

      // TODO: Send invitation email via Resend
      // await _sendInvitationEmail(email, role, invitationToken);

      return {
        'success': true,
        'invitation_id': response['id'],
        'invitation_token': invitationToken,
        'message': 'Invitation sent successfully',
      };
    } catch (e) {
      print('Error inviting team member: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Accept role invitation
  Future<Map<String, dynamic>> acceptInvitation(
    String invitationToken,
    String userId,
  ) async {
    try {
      final invitation = await _supabase
          .from('role_invitations')
          .select('*')
          .eq('invitation_token', invitationToken)
          .eq('status', 'pending')
          .single();

      // Check if expired
      final expiresAt = DateTime.parse(invitation['expires_at']);
      if (expiresAt.isBefore(DateTime.now())) {
        await _supabase
            .from('role_invitations')
            .update({'status': 'expired'})
            .eq('id', invitation['id']);

        return {'success': false, 'error': 'Invitation has expired'};
      }

      // Assign role
      await assignRole(
        userId: userId,
        role: invitation['invited_role'],
        assignedBy: invitation['invited_by'],
        assignmentReason: 'Accepted invitation',
      );

      // Update invitation status
      await _supabase
          .from('role_invitations')
          .update({
            'status': 'accepted',
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invitation['id']);

      return {
        'success': true,
        'role': invitation['invited_role'],
        'message': 'Invitation accepted successfully',
      };
    } catch (e) {
      print('Error accepting invitation: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get role-based dashboard data
  Future<Map<String, dynamic>> getRoleDashboardData(String userId) async {
    try {
      final userRole = await _getUserRole(userId);
      final permissions = await getRolePermissions(userRole);

      return {
        'role': userRole,
        'permissions': permissions,
        'color_code': roleColors[userRole] ?? 'gray',
        'hierarchy_level': roleHierarchy[userRole] ?? 0,
      };
    } catch (e) {
      print('Error fetching role dashboard data: $e');
      return {};
    }
  }

  /// Get team members by role
  Future<List<Map<String, dynamic>>> getTeamMembersByRole(String role) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('id, full_name, email, avatar_url, created_at')
          .eq('role', role)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching team members: $e');
      return [];
    }
  }

  /// Get role activity logs
  Future<List<Map<String, dynamic>>> getRoleActivityLogs({
    String? actorId,
    String? role,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('role_activity_logs')
          .select('*, actor:user_profiles!actor_id(full_name, avatar_url)')
          .order('performed_at', ascending: false)
          .limit(limit);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching role activity logs: $e');
      return [];
    }
  }

  /// Get role analytics
  Future<Map<String, dynamic>> getRoleAnalytics() async {
    try {
      final response = await _supabase
          .from('role_analytics')
          .select('*')
          .eq('analytics_date', DateTime.now().toIso8601String().split('T')[0])
          .order('active_members', ascending: false);

      return {
        'analytics': List<Map<String, dynamic>>.from(response),
        'total_team_members': response.fold<int>(
          0,
          (sum, item) => sum + (item['active_members'] as int),
        ),
      };
    } catch (e) {
      print('Error fetching role analytics: $e');
      return {'analytics': [], 'total_team_members': 0};
    }
  }

  /// Log role-based activity
  Future<void> _logRoleActivity({
    required String actorId,
    required String actionType,
    String? targetResource,
    String? targetId,
    Map<String, dynamic>? actionDetails,
  }) async {
    try {
      final actorRole = await _getUserRole(actorId);

      await _supabase.from('role_activity_logs').insert({
        'actor_id': actorId,
        'actor_role': actorRole,
        'action_type': actionType,
        'target_resource': targetResource,
        'target_id': targetId,
        'action_details': actionDetails,
      });
    } catch (e) {
      print('Error logging role activity: $e');
    }
  }

  /// Get user role
  Future<String> _getUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('role')
          .eq('id', userId)
          .single();

      return response['role'] ?? 'user';
    } catch (e) {
      print('Error fetching user role: $e');
      return 'user';
    }
  }

  /// Generate invitation token
  String _generateInvitationToken() {
    return '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond * 1000}';
  }

  /// Get pending invitations
  Future<List<Map<String, dynamic>>> getPendingInvitations(
    String invitedBy,
  ) async {
    try {
      final response = await _supabase
          .from('role_invitations')
          .select('*')
          .eq('invited_by', invitedBy)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching pending invitations: $e');
      return [];
    }
  }

  /// Revoke invitation
  Future<Map<String, dynamic>> revokeInvitation(String invitationId) async {
    try {
      await _supabase
          .from('role_invitations')
          .update({'status': 'revoked'})
          .eq('id', invitationId);

      return {'success': true, 'message': 'Invitation revoked successfully'};
    } catch (e) {
      print('Error revoking invitation: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create multi-role approval workflow definition.
  Future<Map<String, dynamic>> createApprovalWorkflow({
    required String tenantId,
    required String workflowName,
    required List<String> requiredRoles,
    required int minApprovals,
  }) async {
    try {
      final res = await _supabase
          .from('enterprise_approval_workflows')
          .insert({
            'tenant_id': tenantId,
            'workflow_name': workflowName,
            'required_roles': requiredRoles,
            'min_approvals': minApprovals,
          })
          .select()
          .single();
      return {'success': true, 'data': res};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Submit approval request that requires multi-role sign-off.
  Future<Map<String, dynamic>> submitApprovalRequest({
    required String workflowId,
    required String requesterId,
    required String requestType,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final res = await _supabase
          .from('enterprise_approval_requests')
          .insert({
            'workflow_id': workflowId,
            'requester_id': requesterId,
            'request_type': requestType,
            'payload': payload,
            'status': 'pending',
          })
          .select()
          .single();
      return {'success': true, 'data': res};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Record an approval/rejection decision for a request.
  Future<Map<String, dynamic>> recordApprovalDecision({
    required String requestId,
    required String approverRole,
    required String decision, // approved | rejected
    String? note,
  }) async {
    try {
      final res = await _supabase
          .from('enterprise_approval_decisions')
          .insert({
            'request_id': requestId,
            'approver_role': approverRole,
            'decision': decision,
            'note': note,
          })
          .select()
          .single();
      return {'success': true, 'data': res};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
