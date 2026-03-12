import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import './supabase_service.dart';
import './auth_service.dart';

class OTPVerificationService {
  static OTPVerificationService? _instance;
  static OTPVerificationService get instance =>
      _instance ??= OTPVerificationService._();

  OTPVerificationService._();

  final _supabase = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  final Dio _dio = Dio();
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1';

  /// Create and send OTP verification code
  Future<OTPResult> createOTPVerification({
    required String electionId,
    required String email,
    String? ipAddress,
    String? deviceFingerprint,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return OTPResult(success: false, message: 'User must be authenticated');
      }

      final userId = _auth.currentUser!.id;

      // Call database function to create OTP
      final response = await _supabase.rpc(
        'create_otp_verification',
        params: {
          'p_election_id': electionId,
          'p_user_id': userId,
          'p_email': email,
          'p_ip_address': ipAddress,
          'p_device_fingerprint': deviceFingerprint,
        },
      );

      if (response == null || response.isEmpty) {
        return OTPResult(
          success: false,
          message: 'Failed to generate OTP code',
        );
      }

      final otpData = response[0] as Map<String, dynamic>;
      final otpCode = otpData['otp_code'] as String;
      final expiresAt = DateTime.parse(otpData['expires_at'] as String);

      // Send OTP via email using Edge Function
      final emailSent = await _sendOTPEmail(
        email: email,
        otpCode: otpCode,
        electionId: electionId,
      );

      if (!emailSent) {
        return OTPResult(
          success: false,
          message: 'Failed to send verification email',
        );
      }

      return OTPResult(
        success: true,
        message: 'Verification code sent to $email',
        expiresAt: expiresAt,
      );
    } catch (e) {
      debugPrint('Create OTP verification error: $e');
      return OTPResult(
        success: false,
        message: 'Failed to create verification: ${e.toString()}',
      );
    }
  }

  /// Verify OTP code
  Future<OTPResult> verifyOTPCode({
    required String electionId,
    required String otpCode,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return OTPResult(success: false, message: 'User must be authenticated');
      }

      final userId = _auth.currentUser!.id;

      // Call database function to verify OTP
      final response = await _supabase.rpc(
        'verify_otp_code',
        params: {
          'p_election_id': electionId,
          'p_user_id': userId,
          'p_otp_code': otpCode,
        },
      );

      if (response == null || response.isEmpty) {
        return OTPResult(success: false, message: 'Verification failed');
      }

      final result = response[0] as Map<String, dynamic>;
      return OTPResult(
        success: result['success'] as bool,
        message: result['message'] as String,
      );
    } catch (e) {
      debugPrint('Verify OTP code error: $e');
      return OTPResult(
        success: false,
        message: 'Verification error: ${e.toString()}',
      );
    }
  }

  /// Check if user has verified email for election
  Future<bool> hasVerifiedEmail(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final userId = _auth.currentUser!.id;

      final response = await _supabase.rpc(
        'has_verified_email_for_election',
        params: {'p_election_id': electionId, 'p_user_id': userId},
      );

      return response as bool? ?? false;
    } catch (e) {
      debugPrint('Check verified email error: $e');
      return false;
    }
  }

  /// Get OTP verification status
  Future<Map<String, dynamic>?> getOTPStatus(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final userId = _auth.currentUser!.id;

      final response = await _supabase
          .from('email_otp_verifications')
          .select()
          .eq('election_id', electionId)
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get OTP status error: $e');
      return null;
    }
  }

  /// Resend OTP code (with rate limiting)
  Future<OTPResult> resendOTPCode({
    required String electionId,
    required String email,
  }) async {
    try {
      // Check last send time
      final status = await getOTPStatus(electionId);
      if (status != null) {
        final createdAt = DateTime.parse(status['created_at'] as String);
        final timeSinceLastSend = DateTime.now().difference(createdAt);

        // Rate limit: 1 minute between resends
        if (timeSinceLastSend.inSeconds < 60) {
          final waitSeconds = 60 - timeSinceLastSend.inSeconds;
          return OTPResult(
            success: false,
            message: 'Please wait $waitSeconds seconds before resending',
          );
        }
      }

      // Create new OTP
      return await createOTPVerification(electionId: electionId, email: email);
    } catch (e) {
      debugPrint('Resend OTP error: $e');
      return OTPResult(
        success: false,
        message: 'Failed to resend code: ${e.toString()}',
      );
    }
  }

  /// Send OTP email via Edge Function
  Future<bool> _sendOTPEmail({
    required String email,
    required String otpCode,
    required String electionId,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;

      // Get election details
      final election = await _supabase
          .from('elections')
          .select('title')
          .eq('id', electionId)
          .maybeSingle();

      final electionTitle = election?['title'] ?? 'Election';

      final response = await _dio.post(
        '$_baseUrl/send-otp-email',
        data: {
          'to': email,
          'otp_code': otpCode,
          'election_title': electionTitle,
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
      debugPrint('Send OTP email error: $e');
      return false;
    }
  }

  /// Get OTP analytics for election
  Future<Map<String, dynamic>> getOTPAnalytics(String electionId) async {
    try {
      final response = await _supabase
          .from('email_otp_verifications')
          .select()
          .eq('election_id', electionId);

      final verifications = List<Map<String, dynamic>>.from(response);

      final totalSent = verifications.length;
      final totalVerified = verifications
          .where((v) => v['verified_at'] != null)
          .length;
      final successRate = totalSent > 0
          ? (totalVerified / totalSent * 100).toStringAsFixed(1)
          : '0.0';

      // Calculate average time to verify
      final verifiedOTPs = verifications.where((v) => v['verified_at'] != null);
      double avgTimeSeconds = 0;

      if (verifiedOTPs.isNotEmpty) {
        final totalTime = verifiedOTPs.fold<int>(0, (sum, v) {
          final created = DateTime.parse(v['created_at'] as String);
          final verified = DateTime.parse(v['verified_at'] as String);
          return sum + verified.difference(created).inSeconds;
        });
        avgTimeSeconds = totalTime / verifiedOTPs.length;
      }

      return {
        'total_sent': totalSent,
        'total_verified': totalVerified,
        'success_rate': successRate,
        'avg_time_to_verify_seconds': avgTimeSeconds.toInt(),
      };
    } catch (e) {
      debugPrint('Get OTP analytics error: $e');
      return {
        'total_sent': 0,
        'total_verified': 0,
        'success_rate': '0.0',
        'avg_time_to_verify_seconds': 0,
      };
    }
  }
}

class OTPResult {
  final bool success;
  final String message;
  final DateTime? expiresAt;

  OTPResult({required this.success, required this.message, this.expiresAt});
}
