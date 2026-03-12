import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class AdvertiserRegistrationService {
  static AdvertiserRegistrationService? _instance;
  static AdvertiserRegistrationService get instance =>
      _instance ??= AdvertiserRegistrationService._();

  AdvertiserRegistrationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  Future<Map<String, dynamic>> createRegistration({
    required String companyName,
    required String companyEmail,
    required String industryClassification,
    String? companyWebsite,
    String? companyPhone,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('advertiser_registrations')
          .insert({
            'user_id': _auth.currentUser!.id,
            'company_name': companyName,
            'company_email': companyEmail,
            'industry_classification': industryClassification,
            'company_website': companyWebsite,
            'company_phone': companyPhone,
            'registration_status': 'pending',
            'kyc_status': 'not_started',
            'current_step': 1,
            'total_steps': 6,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Create registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getRegistration() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('advertiser_registrations')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get registration error: $e');
      return null;
    }
  }

  Future<bool> updateRegistrationStep({
    required String registrationId,
    required int currentStep,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updates = {
        'current_step': currentStep,
        if (additionalData != null) ...additionalData,
      };

      await _client
          .from('advertiser_registrations')
          .update(updates)
          .eq('id', registrationId);

      return true;
    } catch (e) {
      debugPrint('Update registration step error: $e');
      return false;
    }
  }

  Future<bool> updateCompanyInfo({
    required String registrationId,
    String? businessRegistrationNumber,
    String? taxIdentificationNumber,
    String? companyWebsite,
    String? companyPhone,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (businessRegistrationNumber != null) {
        updates['business_registration_number'] = businessRegistrationNumber;
      }
      if (taxIdentificationNumber != null) {
        updates['tax_identification_number'] = taxIdentificationNumber;
      }
      if (companyWebsite != null) updates['company_website'] = companyWebsite;
      if (companyPhone != null) updates['company_phone'] = companyPhone;

      if (updates.isEmpty) return false;

      await _client
          .from('advertiser_registrations')
          .update(updates)
          .eq('id', registrationId);

      return true;
    } catch (e) {
      debugPrint('Update company info error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String registrationId,
    required String documentType,
    required String documentName,
    required String fileUrl,
    int? fileSizeBytes,
    String? mimeType,
  }) async {
    try {
      final response = await _client
          .from('advertiser_documents')
          .insert({
            'registration_id': registrationId,
            'document_type': documentType,
            'document_name': documentName,
            'file_url': fileUrl,
            'file_size_bytes': fileSizeBytes,
            'mime_type': mimeType,
            'verification_status': 'pending',
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Upload document error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDocuments(String registrationId) async {
    try {
      final response = await _client
          .from('advertiser_documents')
          .select()
          .eq('registration_id', registrationId)
          .order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get documents error: $e');
      return [];
    }
  }

  Future<bool> addBeneficialOwner({
    required String registrationId,
    required String fullName,
    required double ownershipPercentage,
    String? nationality,
    DateTime? dateOfBirth,
    String? identificationNumber,
    String? identificationType,
  }) async {
    try {
      await _client.from('beneficial_owners').insert({
        'registration_id': registrationId,
        'full_name': fullName,
        'ownership_percentage': ownershipPercentage,
        'nationality': nationality,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'identification_number': identificationNumber,
        'identification_type': identificationType,
      });

      return true;
    } catch (e) {
      debugPrint('Add beneficial owner error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getBeneficialOwners(
    String registrationId,
  ) async {
    try {
      final response = await _client
          .from('beneficial_owners')
          .select()
          .eq('registration_id', registrationId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get beneficial owners error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> runComplianceScreening({
    required String registrationId,
    required String screeningType,
  }) async {
    try {
      final mockResult = {
        'risk_score': 25.0,
        'risk_level': 'low',
        'sanctions_match': false,
        'pep_match': false,
        'adverse_media_match': false,
      };

      final response = await _client
          .from('compliance_screenings')
          .insert({
            'registration_id': registrationId,
            'screening_type': screeningType,
            'screening_provider': 'mock_provider',
            'risk_score': mockResult['risk_score'],
            'risk_level': mockResult['risk_level'],
            'sanctions_match': mockResult['sanctions_match'],
            'pep_match': mockResult['pep_match'],
            'adverse_media_match': mockResult['adverse_media_match'],
            'screening_result': mockResult,
          })
          .select()
          .single();

      await _client
          .from('advertiser_registrations')
          .update({
            'aml_screening_status': mockResult['risk_level'] == 'low'
                ? 'verified'
                : 'pending',
          })
          .eq('id', registrationId);

      return response;
    } catch (e) {
      debugPrint('Run compliance screening error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getComplianceScreenings(
    String registrationId,
  ) async {
    try {
      final response = await _client
          .from('compliance_screenings')
          .select()
          .eq('registration_id', registrationId)
          .order('screened_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get compliance screenings error: $e');
      return [];
    }
  }

  Future<bool> updateBillingInfo({
    required String registrationId,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
  }) async {
    try {
      final existing = await _client
          .from('advertiser_billing_info')
          .select()
          .eq('registration_id', registrationId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('advertiser_billing_info')
            .update({
              'billing_address_line1': addressLine1,
              'billing_address_line2': addressLine2,
              'billing_city': city,
              'billing_state': state,
              'billing_postal_code': postalCode,
              'billing_country': country,
            })
            .eq('registration_id', registrationId);
      } else {
        await _client.from('advertiser_billing_info').insert({
          'registration_id': registrationId,
          'billing_address_line1': addressLine1,
          'billing_address_line2': addressLine2,
          'billing_city': city,
          'billing_state': state,
          'billing_postal_code': postalCode,
          'billing_country': country,
        });
      }

      return true;
    } catch (e) {
      debugPrint('Update billing info error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getBillingInfo(String registrationId) async {
    try {
      final response = await _client
          .from('advertiser_billing_info')
          .select()
          .eq('registration_id', registrationId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get billing info error: $e');
      return null;
    }
  }

  Future<bool> acceptTerms(String registrationId) async {
    try {
      await _client
          .from('advertiser_registrations')
          .update({
            'terms_accepted': true,
            'terms_accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', registrationId);

      return true;
    } catch (e) {
      debugPrint('Accept terms error: $e');
      return false;
    }
  }

  Future<bool> submitRegistration(String registrationId) async {
    try {
      await _client
          .from('advertiser_registrations')
          .update({
            'submitted_at': DateTime.now().toIso8601String(),
            'registration_status': 'under_review',
            'kyc_status': 'pending_review',
            'current_step': 6,
          })
          .eq('id', registrationId);

      return true;
    } catch (e) {
      debugPrint('Submit registration error: $e');
      return false;
    }
  }

  Future<bool> configureStripePayment({
    required String registrationId,
    required String stripeCustomerId,
  }) async {
    try {
      await _client
          .from('advertiser_registrations')
          .update({
            'stripe_customer_id': stripeCustomerId,
            'payment_method_configured': true,
          })
          .eq('id', registrationId);

      return true;
    } catch (e) {
      debugPrint('Configure Stripe payment error: $e');
      return false;
    }
  }
}
