import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Age Verification Service with Yoti SDK Integration
/// Implements waterfall approach: Facial Estimation → Government ID → Digital Wallet
class AgeVerificationService {
  static AgeVerificationService? _instance;
  static AgeVerificationService get instance =>
      _instance ??= AgeVerificationService._();

  AgeVerificationService._();

  final AuthService _auth = AuthService.instance;
  final Uuid _uuid = const Uuid();

  /// Check if user has valid age verification
  Future<bool> hasValidAgeVerification(String userId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('age_verifications')
          .select()
          .eq('user_id', userId)
          .eq('verification_status', 'verified')
          .gte(
            'verified_at',
            DateTime.now().subtract(Duration(days: 365)).toIso8601String(),
          )
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Check age verification error: $e');
      return false;
    }
  }

  /// Start age verification process
  Future<String?> startAgeVerification({
    required String electionId,
    String verificationMethod = 'facial_estimation',
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final verificationId = _uuid.v4();

      await SupabaseService.instance.client.from('age_verifications').insert({
        'id': verificationId,
        'user_id': _auth.currentUser!.id,
        'election_id': electionId,
        'verification_method': verificationMethod,
        'verification_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      return verificationId;
    } catch (e) {
      debugPrint('Start age verification error: $e');
      return null;
    }
  }

  /// Submit facial age estimation (Yoti SDK)
  Future<Map<String, dynamic>?> submitFacialEstimation({
    required String verificationId,
    required String selfieImageBase64,
  }) async {
    try {
      // In production, this would call Yoti SDK API
      // For now, simulate the response
      final estimatedAge = 25; // Simulated Yoti response
      final confidenceScore = 0.92; // 92% confidence

      final isOver18 = estimatedAge >= 18;
      final isBorderline =
          estimatedAge >= 15 && estimatedAge <= 21; // 3-year buffer

      await SupabaseService.instance.client
          .from('age_verifications')
          .update({
            'estimated_age': estimatedAge,
            'confidence_score': confidenceScore,
            'is_borderline': isBorderline,
            'verification_status': isBorderline
                ? 'requires_document'
                : (isOver18 ? 'verified' : 'rejected'),
            'verified_at': isOver18 && !isBorderline
                ? DateTime.now().toIso8601String()
                : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', verificationId);

      // Delete selfie immediately (data minimization)
      await _deleteSelfieImage(verificationId);

      return {
        'verification_id': verificationId,
        'is_over_18': isOver18,
        'is_borderline': isBorderline,
        'requires_document': isBorderline,
        'confidence_score': confidenceScore,
      };
    } catch (e) {
      debugPrint('Submit facial estimation error: $e');
      return null;
    }
  }

  /// Submit government ID verification (fallback for borderline cases)
  Future<Map<String, dynamic>?> submitGovernmentId({
    required String verificationId,
    required String documentType,
    required String documentImageBase64,
    required String selfieImageBase64,
  }) async {
    try {
      // In production, this would call Yoti Document Verification API
      // Simulated response
      final documentVerified = true;
      final biometricMatch = true;
      final extractedDOB = DateTime(1998, 5, 15); // Simulated extraction

      final age = DateTime.now().year - extractedDOB.year;
      final isOver18 = age >= 18;

      await SupabaseService.instance.client
          .from('age_verifications')
          .update({
            'document_type': documentType,
            'document_verified': documentVerified,
            'biometric_match': biometricMatch,
            'verification_status': isOver18 ? 'verified' : 'rejected',
            'verification_method': 'government_id',
            'verified_at': isOver18 ? DateTime.now().toIso8601String() : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', verificationId);

      // Delete images immediately (data minimization)
      await _deleteDocumentImages(verificationId);

      return {
        'verification_id': verificationId,
        'is_over_18': isOver18,
        'document_verified': documentVerified,
        'biometric_match': biometricMatch,
      };
    } catch (e) {
      debugPrint('Submit government ID error: $e');
      return null;
    }
  }

  /// Submit digital identity wallet verification (Yoti Keys/AgeKey)
  Future<Map<String, dynamic>?> submitDigitalWallet({
    required String verificationId,
    required String walletToken,
  }) async {
    try {
      // In production, this would verify Yoti Keys/AgeKey token
      // Simulated response derived from token presence
      final isOver18 = walletToken.isNotEmpty;

      await SupabaseService.instance.client
          .from('age_verifications')
          .update({
            'wallet_token': walletToken,
            'verification_status': isOver18 ? 'verified' : 'rejected',
            'verification_method': 'digital_wallet',
            'verified_at': isOver18 ? DateTime.now().toIso8601String() : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', verificationId);

      return {
        'verification_id': verificationId,
        'is_over_18': isOver18,
        'wallet_verified': true,
      };
    } catch (e) {
      debugPrint('Submit digital wallet error: $e');
      return null;
    }
  }

  /// Get verification status
  Future<Map<String, dynamic>?> getVerificationStatus(
    String verificationId,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('age_verifications')
          .select()
          .eq('id', verificationId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get verification status error: $e');
      return null;
    }
  }

  /// Get election age verification settings
  Future<Map<String, dynamic>?> getElectionAgeSettings(
    String electionId,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('elections')
          .select('require_age_verification, age_verification_methods')
          .eq('id', electionId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get election age settings error: $e');
      return null;
    }
  }

  /// Get compliance report (ISO/IEC 27566-1:2025)
  Future<Map<String, dynamic>> getComplianceReport() async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'get_age_verification_compliance_report',
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Get compliance report error: $e');
      return {};
    }
  }

  /// Delete selfie image (data minimization)
  Future<void> _deleteSelfieImage(String verificationId) async {
    try {
      // In production, delete from storage
      await SupabaseService.instance.client
          .from('age_verification_images')
          .delete()
          .eq('verification_id', verificationId)
          .eq('image_type', 'selfie');

      debugPrint('Selfie image deleted for verification: $verificationId');
    } catch (e) {
      debugPrint('Delete selfie image error: $e');
    }
  }

  /// Delete document images (data minimization)
  Future<void> _deleteDocumentImages(String verificationId) async {
    try {
      // In production, delete from storage
      await SupabaseService.instance.client
          .from('age_verification_images')
          .delete()
          .eq('verification_id', verificationId);

      debugPrint('Document images deleted for verification: $verificationId');
    } catch (e) {
      debugPrint('Delete document images error: $e');
    }
  }
}
