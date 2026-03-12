import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// Service for Stripe Tax API integration
/// Handles automated tax calculations, transaction recording, and compliance tracking
class StripeTaxService {
  static StripeTaxService? _instance;
  static StripeTaxService get instance => _instance ??= StripeTaxService._();

  StripeTaxService._();

  final Dio _dio = Dio();
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1';
  final AuthService _auth = AuthService.instance;

  /// Calculate tax for a transaction using Stripe Tax API
  Future<Map<String, dynamic>?> calculateTax({
    required double amountUsd,
    required String jurisdictionCode,
    required String transactionType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final response = await _dio.post(
        '$_baseUrl/stripe-tax-calculate',
        data: {
          'amount_usd': amountUsd,
          'jurisdiction_code': jurisdictionCode,
          'transaction_type': transactionType,
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
      debugPrint('Calculate tax error: $e');
      return null;
    }
  }

  /// Record transaction for tax compliance reporting
  Future<bool> recordTransaction({
    required String transactionId,
    required double amountUsd,
    required double taxAmountUsd,
    required String jurisdictionCode,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final response = await _dio.post(
        '$_baseUrl/stripe-tax-record-transaction',
        data: {
          'transaction_id': transactionId,
          'amount_usd': amountUsd,
          'tax_amount_usd': taxAmountUsd,
          'jurisdiction_code': jurisdictionCode,
          'creator_id': _auth.currentUser!.id,
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
      debugPrint('Record transaction error: $e');
      return false;
    }
  }

  /// Get tax calculations history
  Future<List<Map<String, dynamic>>> getTaxCalculations({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      var query = SupabaseService.instance.client
          .from('stripe_tax_calculations')
          .select()
          .eq('creator_id', _auth.currentUser!.id);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get tax calculations error: $e');
      return [];
    }
  }
}
