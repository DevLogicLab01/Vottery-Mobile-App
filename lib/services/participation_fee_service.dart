import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './payment_service.dart';
import './supabase_service.dart';

/// Service for managing participation fees, regional pricing, and fee payments
class ParticipationFeeService {
  static ParticipationFeeService? _instance;
  static ParticipationFeeService get instance =>
      _instance ??= ParticipationFeeService._();

  ParticipationFeeService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  PaymentService get _paymentService => PaymentService.instance;

  static const Map<String, String> _zoneCurrencyMap = {
    'region1': 'USD',
    'region2': 'EUR',
    'region3': 'USD',
    'region4': 'USD',
    'region5': 'USD',
    'region6': 'USD',
    'region7': 'AUD',
    'region8': 'CNY',
  };

  /// Check if participation fees are globally enabled
  Future<bool> isFeatureEnabled() async {
    try {
      final response = await _client
          .from('platform_feature_controls')
          .select('is_globally_enabled')
          .eq('feature_name', 'participation_fees')
          .maybeSingle();

      return response?['is_globally_enabled'] ?? false;
    } catch (e) {
      debugPrint('Check feature enabled error: $e');
      return false;
    }
  }

  /// Check if participation fees are enabled for specific country
  Future<bool> isEnabledForCountry(String countryCode) async {
    try {
      final result = await _client.rpc(
        'is_participation_fee_enabled',
        params: {'p_country_code': countryCode},
      );

      return result ?? false;
    } catch (e) {
      debugPrint('Check country enabled error: $e');
      return false;
    }
  }

  /// Get regional fee for election and zone
  Future<Map<String, dynamic>?> getRegionalFee(
    String electionId,
    String zone,
  ) async {
    try {
      final response = await _client
          .from('election_regional_fees')
          .select()
          .eq('election_id', electionId)
          .eq('zone', zone)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get regional fee error: $e');
      return null;
    }
  }

  /// Get all regional fees for election
  Future<List<Map<String, dynamic>>> getAllRegionalFees(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('election_regional_fees')
          .select()
          .eq('election_id', electionId)
          .eq('is_active', true)
          .order('zone');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all regional fees error: $e');
      return [];
    }
  }

  /// Save regional fees for election
  Future<bool> saveRegionalFees(
    String electionId,
    Map<String, double> regionalFees,
  ) async {
    try {
      // Delete existing fees
      await _client
          .from('election_regional_fees')
          .delete()
          .eq('election_id', electionId);

      // Insert new fees
      final feeRecords = regionalFees.entries.map((entry) {
        final currencyCode = _zoneCurrencyMap[entry.key] ?? 'USD';
        return {
          'election_id': electionId,
          'zone': entry.key,
          'fee_amount': entry.value,
          'currency_code': currencyCode,
          'is_active': true,
        };
      }).toList();

      if (feeRecords.isNotEmpty) {
        await _client.from('election_regional_fees').insert(feeRecords);
      }

      return true;
    } catch (e) {
      debugPrint('Save regional fees error: $e');
      return false;
    }
  }

  /// Check if user has paid participation fee
  Future<bool> hasPaidFee(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final result = await _client.rpc(
        'has_paid_participation_fee',
        params: {
          'p_election_id': electionId,
          'p_user_id': _auth.currentUser!.id,
        },
      );

      return result ?? false;
    } catch (e) {
      debugPrint('Check paid fee error: $e');
      return false;
    }
  }

  /// Get participation fee payment for user and election
  Future<Map<String, dynamic>?> getPayment(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('participation_fee_payments')
          .select()
          .eq('election_id', electionId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get payment error: $e');
      return null;
    }
  }

  /// Process participation fee payment
  Future<PaymentResult> processPayment({
    required String electionId,
    required double amount,
    required String zone,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      // Create payment intent
      final paymentResult = await _paymentService.purchaseVP(
        vpAmount: 0, // No VP for participation fees
        priceUsd: amount,
      );

      if (!paymentResult.success) {
        return paymentResult;
      }

      // Record payment in database
      await _client.rpc(
        'record_participation_fee_payment',
        params: {
          'p_election_id': electionId,
          'p_user_id': _auth.currentUser!.id,
          'p_amount': amount,
          'p_zone': zone,
          'p_stripe_payment_intent_id': paymentResult.paymentIntentId,
        },
      );

      return PaymentResult(
        success: true,
        message: 'Participation fee paid successfully',
        paymentIntentId: paymentResult.paymentIntentId,
      );
    } catch (e) {
      debugPrint('Process payment error: $e');
      return PaymentResult(success: false, message: 'Payment failed: $e');
    }
  }

  /// Get user's participation fee payments
  Future<List<Map<String, dynamic>>> getUserPayments() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('participation_fee_payments')
          .select('*, elections(*)')
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user payments error: $e');
      return [];
    }
  }

  /// Track external election access
  Future<bool> trackExternalAccess({
    required String electionId,
    required String accessSource,
    String? referrerUrl,
    String? ipAddress,
    String? countryCode,
  }) async {
    try {
      final userId = _auth.isAuthenticated ? _auth.currentUser!.id : null;

      await _client.rpc(
        'track_external_access',
        params: {
          'p_election_id': electionId,
          'p_user_id': userId,
          'p_access_source': accessSource,
          'p_referrer_url': referrerUrl,
          'p_ip_address': ipAddress,
          'p_country_code': countryCode,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Track external access error: $e');
      return false;
    }
  }

  /// Get external access analytics for election
  Future<List<Map<String, dynamic>>> getExternalAccessAnalytics(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('external_election_access')
          .select()
          .eq('election_id', electionId)
          .order('accessed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get external access analytics error: $e');
      return [];
    }
  }
}
