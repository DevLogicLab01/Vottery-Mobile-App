import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './auth_service.dart';

class StripeConnectService {
  static StripeConnectService? _instance;
  static StripeConnectService get instance =>
      _instance ??= StripeConnectService._();

  StripeConnectService._();

  final Dio _dio = Dio();
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1';
  final AuthService _auth = AuthService.instance;

  /// Create Stripe Connect Express account for creator
  Future<Map<String, dynamic>?> createConnectAccount({
    required String email,
    required String country,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final response = await _dio.post(
        '$_baseUrl/stripe-create-connect-account',
        data: {
          'email': email,
          'country': country,
          'creator_id': _auth.currentUser!.id,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('Create Connect account error: $e');
      return null;
    }
  }

  /// Get Connect account onboarding link
  Future<String?> getAccountOnboardingLink() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final response = await _dio.post(
        '$_baseUrl/stripe-get-onboarding-link',
        data: {'creator_id': _auth.currentUser!.id},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['url'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('Get onboarding link error: $e');
      return null;
    }
  }

  /// Get Connect account status
  Future<Map<String, dynamic>?> getConnectAccountStatus() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await SupabaseService.instance.client
          .from('stripe_connect_accounts')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get Connect account status error: $e');
      return null;
    }
  }

  /// Request payout
  Future<bool> requestPayout({
    required double amountUsd,
    required int vpAmount,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final response = await _dio.post(
        '$_baseUrl/stripe-request-payout',
        data: {
          'creator_id': _auth.currentUser!.id,
          'amount_usd': amountUsd,
          'vp_amount': vpAmount,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Request payout error: $e');
      return false;
    }
  }

  /// Get payout history
  Future<List<Map<String, dynamic>>> getPayoutHistory() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await SupabaseService.instance.client
          .from('stripe_payouts')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get payout history error: $e');
      return [];
    }
  }

  /// Get payout schedule
  Future<Map<String, dynamic>?> getPayoutSchedule() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await SupabaseService.instance.client
          .from('creator_payout_schedule')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get payout schedule error: $e');
      return null;
    }
  }

  /// Update payout schedule
  Future<bool> updatePayoutSchedule({
    required String frequency,
    required double minimumThreshold,
    required bool autoPayoutEnabled,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await SupabaseService.instance.client
          .from('creator_payout_schedule')
          .upsert({
            'creator_id': _auth.currentUser!.id,
            'schedule_type': frequency,
            'minimum_payout_amount': minimumThreshold,
            'auto_payout_enabled': autoPayoutEnabled,
            'updated_at': DateTime.now().toIso8601String(),
          });

      return true;
    } catch (e) {
      debugPrint('Update payout schedule error: $e');
      return false;
    }
  }

  /// Get subscription billing for user
  Future<Map<String, dynamic>?> getUserSubscription() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await SupabaseService.instance.client
          .from('subscription_billing')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get user subscription error: $e');
      return null;
    }
  }

  /// Get subscription invoices
  Future<List<Map<String, dynamic>>> getSubscriptionInvoices() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final subscription = await getUserSubscription();
      if (subscription == null) return [];

      final response = await SupabaseService.instance.client
          .from('subscription_invoices')
          .select()
          .eq('subscription_id', subscription['id'])
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get subscription invoices error: $e');
      return [];
    }
  }

  /// Get transaction monitoring dashboard data (admin only)
  Future<Map<String, dynamic>> getTransactionMonitoringData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultMonitoringData();

      final response = await SupabaseService.instance.client
          .from('transaction_monitoring_logs')
          .select()
          .gte('transaction_date', startDate.toIso8601String().split('T')[0])
          .lte('transaction_date', endDate.toIso8601String().split('T')[0])
          .order('transaction_date', ascending: false);

      final logs = List<Map<String, dynamic>>.from(response);

      if (logs.isEmpty) return _getDefaultMonitoringData();

      final totalVolume = logs.fold<double>(
        0.0,
        (sum, log) => sum + (log['total_volume_usd'] ?? 0.0),
      );

      final totalRevenue = logs.fold<double>(
        0.0,
        (sum, log) => sum + (log['total_revenue_usd'] ?? 0.0),
      );

      final totalRefunds = logs.fold<double>(
        0.0,
        (sum, log) => sum + (log['total_refunds_usd'] ?? 0.0),
      );

      final totalTransactions = logs.fold<int>(
        0,
        (sum, log) => sum + ((log['transaction_count'] ?? 0) as int),
      );

      return {
        'total_volume_usd': totalVolume,
        'total_revenue_usd': totalRevenue,
        'total_refunds_usd': totalRefunds,
        'total_transactions': totalTransactions,
        'daily_logs': logs,
      };
    } catch (e) {
      debugPrint('Get transaction monitoring data error: $e');
      return _getDefaultMonitoringData();
    }
  }

  /// Get webhook logs (admin only)
  Future<List<Map<String, dynamic>>> getWebhookLogs({int limit = 50}) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await SupabaseService.instance.client
          .from('stripe_webhook_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get webhook logs error: $e');
      return [];
    }
  }

  /// Get dispute management data
  Future<List<Map<String, dynamic>>> getDisputes() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await SupabaseService.instance.client
          .from('dispute_management')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get disputes error: $e');
      return [];
    }
  }

  /// Get refund processing data
  Future<List<Map<String, dynamic>>> getRefunds() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await SupabaseService.instance.client
          .from('refund_processing')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get refunds error: $e');
      return [];
    }
  }

  Map<String, dynamic> _getDefaultMonitoringData() {
    return {
      'total_volume_usd': 0.0,
      'total_revenue_usd': 0.0,
      'total_refunds_usd': 0.0,
      'total_transactions': 0,
      'daily_logs': [],
    };
  }
}
