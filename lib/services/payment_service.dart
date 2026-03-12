import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './logging/platform_logging_service.dart';

/// Service for Stripe payment processing for VP purchases and prize payouts
class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();
  PaymentService._();

  final Dio _dio = Dio();
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1';
  final AuthService _auth = AuthService.instance;

  /// Initialize Stripe with publishable key
  static Future<void> initialize() async {
    try {
      const String publishableKey = String.fromEnvironment(
        'STRIPE_PUBLISHABLE_KEY',
        defaultValue: '',
      );

      if (publishableKey.isEmpty) {
        throw Exception('STRIPE_PUBLISHABLE_KEY must be configured');
      }

      Stripe.publishableKey = publishableKey;

      if (kIsWeb) {
        await Stripe.instance.applySettings();
      }

      debugPrint('Stripe initialized successfully');
    } catch (e) {
      debugPrint('Stripe initialization error: $e');
      rethrow;
    }
  }

  /// Purchase VP (Vottery Points)
  Future<PaymentResult> purchaseVP({
    required int vpAmount,
    required double priceUsd,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      // Create payment intent
      final response = await _createPaymentIntent(
        amount: priceUsd,
        description: 'Purchase $vpAmount VP',
        metadata: {
          'type': 'vp_purchase',
          'vp_amount': vpAmount.toString(),
          'user_id': _auth.currentUser!.id,
        },
      );

      // Process payment
      final paymentResult = await _processPayment(
        clientSecret: response['client_secret'],
      );

      if (paymentResult.success) {
        // Award VP to user
        await _awardVP(vpAmount);

        // ✅ Add logging for successful payment
        await PlatformLoggingService.logPaymentTransaction(
          transactionId: response['payment_intent_id'] ?? 'unknown',
          transactionType: 'vp_purchase',
          amount: priceUsd,
        );
      }

      return paymentResult;
    } catch (e) {
      debugPrint('Purchase VP error: $e');

      // Log payment errors
      await PlatformLoggingService.logEvent(
        eventType: 'payment_error',
        message: 'Payment failed: ${e.toString()}',
        logLevel: 'error',
        logCategory: 'payment',
        sensitiveData: true,
        metadata: {
          'vp_amount': vpAmount,
          'price_usd': priceUsd,
          'error': e.toString(),
        },
      );

      return PaymentResult(success: false, message: 'Purchase failed: $e');
    }
  }

  /// Process prize payout
  Future<bool> processPrizePayout({
    required String electionId,
    required String winnerId,
    required double amount,
  }) async {
    try {
      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final response = await _dio.post(
        '$_baseUrl/process-payout',
        data: {
          'election_id': electionId,
          'winner_id': winnerId,
          'amount': amount,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      final success = response.statusCode == 200;

      if (success) {
        // ✅ Add logging for successful payout
        await PlatformLoggingService.logPaymentTransaction(
          transactionId: response.data['transaction_id'] ?? 'payout',
          transactionType: 'prize_payout',
          amount: amount,
        );
      }

      return success;
    } catch (e) {
      debugPrint('Process payout error: $e');

      // Log payout errors
      await PlatformLoggingService.logEvent(
        eventType: 'payout_error',
        message: 'Prize payout failed: ${e.toString()}',
        logLevel: 'error',
        logCategory: 'payment',
        sensitiveData: true,
        metadata: {
          'election_id': electionId,
          'winner_id': winnerId,
          'amount': amount,
          'error': e.toString(),
        },
      );

      return false;
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent({
    required double amount,
    required String description,
    Map<String, String>? metadata,
  }) async {
    try {
      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final response = await _dio.post(
        '$_baseUrl/create-payment-intent',
        data: {
          'amount': amount,
          'currency': 'usd',
          'description': description,
          'metadata': metadata ?? {},
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {
      debugPrint('Create payment intent error: $e');
      rethrow;
    }
  }

  Future<PaymentResult> _processPayment({required String clientSecret}) async {
    try {
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(paymentMethodData: PaymentMethodData()),
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        return PaymentResult(
          success: true,
          message: 'Payment completed successfully',
          paymentIntentId: paymentIntent.id,
        );
      } else {
        return PaymentResult(
          success: false,
          message: 'Payment failed: ${paymentIntent.status}',
        );
      }
    } on StripeException catch (e) {
      return PaymentResult(
        success: false,
        message: e.error.localizedMessage ?? 'Payment failed',
        errorCode: e.error.code.name,
      );
    } catch (e) {
      return PaymentResult(success: false, message: 'Payment error: $e');
    }
  }

  Future<void> _awardVP(int amount) async {
    try {
      await SupabaseService.instance.client.rpc(
        'award_vp',
        params: {'user_id': _auth.currentUser!.id, 'amount': amount},
      );
    } catch (e) {
      debugPrint('Award VP error: $e');
      rethrow;
    }
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final String? errorCode;
  final String? paymentIntentId;

  PaymentResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.paymentIntentId,
  });
}
