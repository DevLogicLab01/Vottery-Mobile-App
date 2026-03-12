import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// Identity Orchestration Service
/// Backed by Vottery's Supabase Edge Function:
/// - Primary: Sumsub
/// - Fallback: Veriff
/// Legacy Stripe Identity helpers are kept for migration/reference.
class StripeIdentityService {
  static StripeIdentityService? _instance;
  static StripeIdentityService get instance =>
      _instance ??= StripeIdentityService._();

  StripeIdentityService._();

  final Dio _dio = Dio();
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1';
  final AuthService _auth = AuthService.instance;

  /// New: call identity-orchestrator (Sumsub + Veriff).
  Future<Map<String, dynamic>> verifyIdentity({
    required String purpose,
    String? electionId,
    Map<String, dynamic>? sessionContext,
    Map<String, dynamic>? sessionData,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }
      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final response = await _dio.post(
        '$_baseUrl/identity-orchestrator',
        data: {
          'purpose': purpose,
          'userId': _auth.currentUser!.id,
          'electionId': electionId,
          'minAgeRequired': sessionContext?['min_age_required'],
          'geo': sessionContext?['geo'],
          'sessionContext': sessionContext ?? {},
          'sessionData': sessionData ?? {},
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = (response.data as Map).cast<String, dynamic>();
      return {
        'success': data['success'] == true,
        'provider': data['provider'],
        'confidence': data['confidence'],
        'fallbackUsed': data['fallbackUsed'] ?? false,
        'raw': data,
      };
    } catch (e) {
      debugPrint('Identity orchestrator error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Create Stripe Identity VerificationSession
  Future<Map<String, dynamic>?> createVerificationSession({
    required String verificationId,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final response = await _dio.post(
        '$_baseUrl/stripe-create-identity-session',
        data: {
          'creator_id': _auth.currentUser!.id,
          'verification_id': verificationId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Store session in database
        await SupabaseService.instance.client.rpc(
          'create_stripe_identity_session',
          params: {
            'p_creator_id': _auth.currentUser!.id,
            'p_verification_id': verificationId,
            'p_stripe_session_id': data['id'],
            'p_verification_url': data['url'],
            'p_client_secret': data['client_secret'],
          },
        );

        return data;
      }

      return null;
    } catch (e) {
      debugPrint('Create verification session error: $e');
      return null;
    }
  }

  /// Get verification session status
  Future<Map<String, dynamic>?> getVerificationSessionStatus(
    String verificationId,
  ) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await SupabaseService.instance.client
          .from('stripe_identity_sessions')
          .select('*')
          .eq('verification_id', verificationId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get verification session status error: $e');
      return null;
    }
  }

  /// Get identity verification results
  Future<Map<String, dynamic>?> getIdentityVerificationResults(
    String stripeSessionId,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('identity_verification_results')
          .select('*')
          .eq('stripe_session_id', stripeSessionId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get identity verification results error: $e');
      return null;
    }
  }

  /// Get compliance screening results
  Future<List<Map<String, dynamic>>> getComplianceScreeningResults(
    String verificationId,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('compliance_screening_results')
          .select('*')
          .eq('verification_id', verificationId)
          .order('screened_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get compliance screening results error: $e');
      return [];
    }
  }

  /// Submit bank account verification via Stripe Connect
  Future<bool> submitBankAccountVerification({
    required String accountNumber,
    required String routingNumber,
    String? swiftCode,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final response = await _dio.post(
        '$_baseUrl/stripe-verify-bank-account',
        data: {
          'creator_id': _auth.currentUser!.id,
          'account_number': accountNumber,
          'routing_number': routingNumber,
          'swift_code': swiftCode,
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
      debugPrint('Submit bank account verification error: $e');
      return false;
    }
  }

  /// Get verification renewal reminders
  Future<List<Map<String, dynamic>>> getVerificationRenewalReminders() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await SupabaseService.instance.client
          .from('verification_renewal_reminders')
          .select('*')
          .eq('creator_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get verification renewal reminders error: $e');
      return [];
    }
  }

  /// Check if verification is expiring soon
  Future<bool> isVerificationExpiringSoon(String verificationId) async {
    try {
      final verification = await SupabaseService.instance.client
          .from('creator_verification')
          .select('verification_expiry_date')
          .eq('id', verificationId)
          .single();

      if (verification['verification_expiry_date'] == null) return false;

      final expiryDate = DateTime.parse(
        verification['verification_expiry_date'],
      );
      final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

      return daysUntilExpiry <= 30;
    } catch (e) {
      debugPrint('Check verification expiry error: $e');
      return false;
    }
  }

  /// Request verification renewal
  Future<bool> requestVerificationRenewal(String verificationId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Create new verification session for renewal
      final session = await createVerificationSession(
        verificationId: verificationId,
      );

      return session != null;
    } catch (e) {
      debugPrint('Request verification renewal error: $e');
      return false;
    }
  }

  /// Get verification badge status
  Future<Map<String, dynamic>> getVerificationBadgeStatus() async {
    try {
      if (!_auth.isAuthenticated) {
        return {'has_badge': false, 'badge_text': ''};
      }

      final verification = await SupabaseService.instance.client
          .from('creator_verification')
          .select('verification_status, identity_verification_status')
          .eq('creator_id', _auth.currentUser!.id)
          .maybeSingle();

      if (verification == null) {
        return {'has_badge': false, 'badge_text': ''};
      }

      final isVerified =
          verification['verification_status'] == 'approved' &&
          verification['identity_verification_status'] == 'verified';

      return {
        'has_badge': isVerified,
        'badge_text': isVerified ? '✓ ID Verified by Stripe' : '',
      };
    } catch (e) {
      debugPrint('Get verification badge status error: $e');
      return {'has_badge': false, 'badge_text': ''};
    }
  }

  /// Get verification analytics (admin only)
  Future<Map<String, dynamic>> getVerificationAnalytics() async {
    try {
      final allVerifications = await SupabaseService.instance.client
          .from('creator_verification')
          .select('verification_status');

      final total = allVerifications.length;
      final approved = allVerifications
          .where((v) => v['verification_status'] == 'approved')
          .length;
      final rejected = allVerifications
          .where((v) => v['verification_status'] == 'rejected')
          .length;
      final underReview = allVerifications
          .where((v) => v['verification_status'] == 'under_review')
          .length;

      final approvalRate = total > 0 ? (approved / total) * 100 : 0.0;

      return {
        'total_verifications': total,
        'approved_count': approved,
        'rejected_count': rejected,
        'under_review_count': underReview,
        'approval_rate': approvalRate,
      };
    } catch (e) {
      debugPrint('Get verification analytics error: $e');
      return {
        'total_verifications': 0,
        'approved_count': 0,
        'rejected_count': 0,
        'under_review_count': 0,
        'approval_rate': 0.0,
      };
    }
  }

  /// Get common failure reasons
  Future<List<Map<String, dynamic>>> getCommonFailureReasons() async {
    try {
      final rejectedVerifications = await SupabaseService.instance.client
          .from('creator_verification')
          .select('rejection_reason')
          .eq('verification_status', 'rejected')
          .not('rejection_reason', 'is', null);

      // Count occurrences of each reason
      final reasonCounts = <String, int>{};
      for (final v in rejectedVerifications) {
        final reason = v['rejection_reason'] as String;
        reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
      }

      // Convert to list and sort by count
      final reasons =
          reasonCounts.entries
              .map((e) => {'reason': e.key, 'count': e.value})
              .toList()
            ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return reasons;
    } catch (e) {
      debugPrint('Get common failure reasons error: $e');
      return [];
    }
  }
}
