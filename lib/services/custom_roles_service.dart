/// Custom roles service - foundation for admin-defined roles.
/// Uses admin_roles and user_admin_roles tables.
/// Keep in sync with Web: src/services/customRolesService.js

import '../services/supabase_service.dart';

class CustomRolesService {
  CustomRolesService._();

  static final CustomRolesService _instance = CustomRolesService._();
  static CustomRolesService get instance => _instance;

  final _client = SupabaseService.instance.client;

  /// Fetch all custom admin roles
  Future<List<Map<String, dynamic>>> getAdminRoles() async {
    final res = await _client
        .from('admin_roles')
        .select()
        .order('display_name');
    return List<Map<String, dynamic>>.from(res);
  }

  /// Fetch roles assigned to a user
  Future<List<Map<String, dynamic>>> getUserAdminRoles(String userId) async {
    if (userId.isEmpty) return [];
    final res = await _client
        .from('user_admin_roles')
        .select('role_id, admin_roles(id, role_name, display_name, description, permissions)')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Check if user has a specific custom role by name
  Future<bool> userHasCustomRole(String userId, String roleName) async {
    final roles = await getUserAdminRoles(userId);
    return roles.any((r) {
      final ar = r['admin_roles'];
      return ar is Map && ar['role_name'] == roleName;
    });
  }

  /// Assign role to user (admin only - enforced by RLS)
  Future<void> assignRoleToUser(String userId, String roleId) async {
    await _client.from('user_admin_roles').upsert(
      {'user_id': userId, 'role_id': roleId},
      onConflict: 'user_id,role_id',
    );
  }

  /// Remove role from user
  Future<void> removeRoleFromUser(String userId, String roleId) async {
    await _client
        .from('user_admin_roles')
        .delete()
        .eq('user_id', userId)
        .eq('role_id', roleId);
  }
}
