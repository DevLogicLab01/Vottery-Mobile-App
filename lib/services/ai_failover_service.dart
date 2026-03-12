import 'package:supabase_flutter/supabase_flutter.dart';

/// Custom exception for permission denied errors
class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}

/// Service for querying AI failover data from Supabase
/// Handles RLS-enforced admin-only access to active_automatic_fallbacks view
class AIFailoverService {
  static final AIFailoverService instance = AIFailoverService._internal();
  AIFailoverService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch active failovers from the secured view
  /// Throws [PermissionDeniedException] if user is not an admin
  Future<List<Map<String, dynamic>>> getActiveFailovers() async {
    try {
      final response = await _supabase
          .from('active_automatic_fallbacks')
          .select();
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        // Permission denied - user is not an admin
        throw const PermissionDeniedException(
          'Admin access required to view AI failover data',
        );
      } else if (e.code == '42P01') {
        // Undefined table/view
        throw Exception(
          'Failover monitoring not available. Please contact support.',
        );
      } else {
        rethrow;
      }
    } on Exception catch (e) {
      throw Exception('Failed to load active failovers: $e');
    }
  }

  /// Check if current user has admin access
  Future<bool> checkAdminAccess() async {
    try {
      final response = await _supabase.rpc('is_admin');
      return response == true;
    } catch (_) {
      return false;
    }
  }

  /// Fetch failover history with error handling
  Future<List<Map<String, dynamic>>> getFailoverHistory({
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('ai_service_failovers')
          .select()
          .order('triggered_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const PermissionDeniedException(
          'Admin access required to view AI failover history',
        );
      } else if (e.code == '42P01') {
        throw Exception(
          'Failover history not available. Please contact support.',
        );
      } else {
        rethrow;
      }
    } on Exception catch (e) {
      throw Exception('Failed to load failover history: $e');
    }
  }

  /// Fetch AI service health data
  Future<List<Map<String, dynamic>>> getServiceHealth() async {
    try {
      final response = await _supabase
          .from('ai_service_health')
          .select()
          .order('last_check_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const PermissionDeniedException(
          'Admin access required to view AI service health data',
        );
      } else if (e.code == '42P01') {
        return []; // Table may not exist yet
      } else {
        rethrow;
      }
    } on Exception catch (e) {
      throw Exception('Failed to load service health: $e');
    }
  }
}
