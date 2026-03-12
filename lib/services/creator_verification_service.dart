import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class CreatorVerificationService {
  static CreatorVerificationService? _instance;
  static CreatorVerificationService get instance =>
      _instance ??= CreatorVerificationService._();

  CreatorVerificationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  static const String kycDocumentsBucket = 'kyc-documents';

  /// Get current verification status
  Future<Map<String, dynamic>?> getVerificationStatus() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('creator_verification')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get verification status error: $e');
      return null;
    }
  }

  /// Submit Step 1: Personal Information
  Future<bool> submitPersonalInformation({
    required String fullName,
    required DateTime dateOfBirth,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required String phone,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('creator_verification').upsert({
        'creator_id': _auth.currentUser!.id,
        'full_name': fullName,
        'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'phone': phone,
        'verification_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Submit personal information error: $e');
      return false;
    }
  }

  /// Submit Step 2: Identity Document Upload
  Future<bool> uploadIdentityDocument({
    required String documentType,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Get verification record
      final verification = await getVerificationStatus();
      if (verification == null) {
        debugPrint('No verification record found');
        return false;
      }

      // Upload document to Supabase Storage
      final filePath = '${_auth.currentUser!.id}/$documentType/$fileName';
      await _client.storage
          .from(kycDocumentsBucket)
          .uploadBinary(
            filePath,
            Uint8List.fromList(fileBytes),
            fileOptions: FileOptions(
              contentType: _getContentType(fileName),
              upsert: true,
            ),
          );

      // Get public URL
      final documentUrl = _client.storage
          .from(kycDocumentsBucket)
          .getPublicUrl(filePath);

      // Save document record
      await _client.from('creator_verification_documents').insert({
        'verification_id': verification['id'],
        'document_type': documentType,
        'document_url': documentUrl,
        'file_name': fileName,
        'file_size': fileBytes.length,
      });

      return true;
    } catch (e) {
      debugPrint('Upload identity document error: $e');
      return false;
    }
  }

  /// Submit Step 3: Bank Account Verification
  Future<bool> submitBankAccountDetails({
    required String accountNumber,
    required String routingNumber,
    String? swiftCode,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('creator_verification')
          .update({
            'bank_account_number': accountNumber,
            'bank_routing_number': routingNumber,
            'bank_swift_code': swiftCode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('creator_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Submit bank account details error: $e');
      return false;
    }
  }

  /// Submit Step 4: Tax Documentation
  Future<bool> submitTaxDocumentation({
    required String taxId,
    required String taxDocumentType,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Update tax information
      await _client
          .from('creator_verification')
          .update({
            'tax_id': taxId,
            'tax_document_type': taxDocumentType,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('creator_id', _auth.currentUser!.id);

      // Upload tax document
      await uploadIdentityDocument(
        documentType: taxDocumentType,
        fileBytes: fileBytes,
        fileName: fileName,
      );

      return true;
    } catch (e) {
      debugPrint('Submit tax documentation error: $e');
      return false;
    }
  }

  /// Submit Step 5: Final Submission for Compliance Screening
  Future<bool> submitForComplianceScreening() async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('creator_verification')
          .update({
            'verification_status': 'under_review',
            'submitted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('creator_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Submit for compliance screening error: $e');
      return false;
    }
  }

  /// Get uploaded documents
  Future<List<Map<String, dynamic>>> getUploadedDocuments() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final verification = await getVerificationStatus();
      if (verification == null) return [];

      final response = await _client
          .from('creator_verification_documents')
          .select()
          .eq('verification_id', verification['id'])
          .order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get uploaded documents error: $e');
      return [];
    }
  }

  /// Check if verification is approved
  Future<bool> isVerificationApproved() async {
    try {
      final status = await getVerificationStatus();
      return status?['verification_status'] == 'approved';
    } catch (e) {
      debugPrint('Check verification approved error: $e');
      return false;
    }
  }

  /// Check if verification is expired
  Future<bool> isVerificationExpired() async {
    try {
      final status = await getVerificationStatus();
      if (status == null) return false;

      final expiryDate = status['verification_expiry'];
      if (expiryDate == null) return false;

      return DateTime.parse(expiryDate).isBefore(DateTime.now());
    } catch (e) {
      debugPrint('Check verification expired error: $e');
      return false;
    }
  }

  /// Get verification progress (completed steps)
  Future<Map<String, bool>> getVerificationProgress() async {
    try {
      final status = await getVerificationStatus();
      if (status == null) {
        return {
          'step1_personal_info': false,
          'step2_identity_document': false,
          'step3_bank_account': false,
          'step4_tax_documentation': false,
          'step5_submitted': false,
        };
      }

      final documents = await getUploadedDocuments();
      final hasIdentityDoc = documents.any(
        (doc) =>
            doc['document_type'] == 'passport' ||
            doc['document_type'] == 'drivers_license' ||
            doc['document_type'] == 'national_id',
      );
      final hasTaxDoc = documents.any(
        (doc) =>
            doc['document_type'] == 'tax_document_w9' ||
            doc['document_type'] == 'tax_document_w8ben',
      );

      return {
        'step1_personal_info':
            status['full_name'] != null &&
            status['date_of_birth'] != null &&
            status['address_line1'] != null,
        'step2_identity_document': hasIdentityDoc,
        'step3_bank_account':
            status['bank_account_number'] != null &&
            status['bank_routing_number'] != null,
        'step4_tax_documentation': status['tax_id'] != null && hasTaxDoc,
        'step5_submitted':
            status['verification_status'] == 'under_review' ||
            status['verification_status'] == 'approved',
      };
    } catch (e) {
      debugPrint('Get verification progress error: $e');
      return {
        'step1_personal_info': false,
        'step2_identity_document': false,
        'step3_bank_account': false,
        'step4_tax_documentation': false,
        'step5_submitted': false,
      };
    }
  }

  /// Resubmit verification after rejection
  Future<bool> resubmitVerification() async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('creator_verification')
          .update({
            'verification_status': 'pending',
            'rejection_reason': null,
            'submitted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('creator_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Resubmit verification error: $e');
      return false;
    }
  }

  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
