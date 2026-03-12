import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './stripe_connect_service.dart';

class BrandOnboardingService {
  static BrandOnboardingService? _instance;
  static BrandOnboardingService get instance =>
      _instance ??= BrandOnboardingService._();

  BrandOnboardingService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  StripeConnectService get _stripe => StripeConnectService.instance;

  /// Get current onboarding progress
  Future<Map<String, dynamic>?> getOnboardingProgress() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('brand_onboarding')
          .select('*, brand_accounts(*)')
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get onboarding progress error: $e');
      return null;
    }
  }

  /// Create or update onboarding record
  Future<String?> createOrUpdateOnboarding({
    required int currentStep,
    Map<String, dynamic>? companyInfo,
    Map<String, dynamic>? verificationDocuments,
    Map<String, dynamic>? paymentSetup,
    Map<String, dynamic>? targetingConfig,
    Map<String, dynamic>? budgetAllocation,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final existing = await getOnboardingProgress();

      final data = {
        'user_id': _auth.currentUser!.id,
        'current_step': currentStep,
        if (companyInfo != null) 'company_info': companyInfo,
        if (verificationDocuments != null)
          'verification_documents': verificationDocuments,
        if (paymentSetup != null) 'payment_setup': paymentSetup,
        if (targetingConfig != null) 'targeting_config': targetingConfig,
        if (budgetAllocation != null) 'budget_allocation': budgetAllocation,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing == null) {
        final response = await _client
            .from('brand_onboarding')
            .insert(data)
            .select()
            .single();
        return response['id'] as String;
      } else {
        await _client
            .from('brand_onboarding')
            .update(data)
            .eq('id', existing['id']);
        return existing['id'] as String;
      }
    } catch (e) {
      debugPrint('Create/update onboarding error: $e');
      return null;
    }
  }

  /// Complete Step 1: Company Registration
  Future<bool> completeCompanyRegistration({
    required String businessName,
    required String registrationNumber,
    required String industry,
    required String taxId,
    required String contactEmail,
    required String contactPhone,
  }) async {
    try {
      final companyInfo = {
        'business_name': businessName,
        'registration_number': registrationNumber,
        'industry': industry,
        'tax_id': taxId,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
      };

      final onboardingId = await createOrUpdateOnboarding(
        currentStep: 2,
        companyInfo: companyInfo,
      );

      return onboardingId != null;
    } catch (e) {
      debugPrint('Complete company registration error: $e');
      return false;
    }
  }

  /// Complete Step 2: Brand Verification
  Future<bool> completeBrandVerification({
    required List<String> documentUrls,
    required Map<String, dynamic> businessLicense,
    required Map<String, dynamic> ownershipDisclosure,
  }) async {
    try {
      final verificationDocs = {
        'document_urls': documentUrls,
        'business_license': businessLicense,
        'ownership_disclosure': ownershipDisclosure,
        'submitted_at': DateTime.now().toIso8601String(),
      };

      final onboardingId = await createOrUpdateOnboarding(
        currentStep: 3,
        verificationDocuments: verificationDocs,
      );

      return onboardingId != null;
    } catch (e) {
      debugPrint('Complete brand verification error: $e');
      return false;
    }
  }

  /// Complete Step 3: Payment Method Setup
  Future<Map<String, dynamic>?> completePaymentSetup({
    required String cardToken,
    required String billingAddress,
    required String subscriptionTier,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      // Create Stripe customer
      final onboarding = await getOnboardingProgress();
      final companyInfo = onboarding?['company_info'] as Map<String, dynamic>?;

      if (companyInfo == null) {
        throw Exception('Company info not found');
      }

      // In production, call Stripe API to create customer and subscription
      // For now, store payment setup info
      final paymentSetup = {
        'card_token': cardToken,
        'billing_address': billingAddress,
        'subscription_tier': subscriptionTier,
        'setup_at': DateTime.now().toIso8601String(),
      };

      final onboardingId = await createOrUpdateOnboarding(
        currentStep: 4,
        paymentSetup: paymentSetup,
      );

      if (onboardingId != null) {
        return {'success': true, 'onboarding_id': onboardingId};
      }

      return null;
    } catch (e) {
      debugPrint('Complete payment setup error: $e');
      return null;
    }
  }

  /// Complete Step 4: Audience Targeting Configuration
  Future<bool> completeTargetingConfig({
    required List<String> demographics,
    required List<String> geographicTargets,
    required List<String> interestCategories,
    required int estimatedReach,
  }) async {
    try {
      final targetingConfig = {
        'demographics': demographics,
        'geographic_targets': geographicTargets,
        'interest_categories': interestCategories,
        'estimated_reach': estimatedReach,
        'configured_at': DateTime.now().toIso8601String(),
      };

      final onboardingId = await createOrUpdateOnboarding(
        currentStep: 5,
        targetingConfig: targetingConfig,
      );

      return onboardingId != null;
    } catch (e) {
      debugPrint('Complete targeting config error: $e');
      return false;
    }
  }

  /// Complete Step 5: Campaign Budget Allocation
  Future<bool> completeBudgetAllocation({
    required double dailyBudget,
    required double monthlyBudget,
    required String biddingStrategy,
    required double costPerVote,
    required Map<String, dynamic> roiProjections,
  }) async {
    try {
      final budgetAllocation = {
        'daily_budget': dailyBudget,
        'monthly_budget': monthlyBudget,
        'bidding_strategy': biddingStrategy,
        'cost_per_vote': costPerVote,
        'roi_projections': roiProjections,
        'allocated_at': DateTime.now().toIso8601String(),
      };

      final onboardingId = await createOrUpdateOnboarding(
        currentStep: 5,
        budgetAllocation: budgetAllocation,
      );

      if (onboardingId != null) {
        // Mark onboarding as completed and create brand account
        await _completeOnboarding(onboardingId);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Complete budget allocation error: $e');
      return false;
    }
  }

  /// Finalize onboarding and create brand account
  Future<bool> _completeOnboarding(String onboardingId) async {
    try {
      final onboarding = await _client
          .from('brand_onboarding')
          .select()
          .eq('id', onboardingId)
          .single();

      final companyInfo = onboarding['company_info'] as Map<String, dynamic>;
      final paymentSetup = onboarding['payment_setup'] as Map<String, dynamic>;
      final targetingConfig =
          onboarding['targeting_config'] as Map<String, dynamic>;
      final budgetAllocation =
          onboarding['budget_allocation'] as Map<String, dynamic>;

      // Create brand account
      final brandAccount = await _client
          .from('brand_accounts')
          .insert({
            'user_id': _auth.currentUser!.id,
            'brand_name': companyInfo['business_name'],
            'industry': companyInfo['industry'],
            'contact_email': companyInfo['contact_email'],
            'contact_phone': companyInfo['contact_phone'],
            'company_registration_number': companyInfo['registration_number'],
            'tax_identification': companyInfo['tax_id'],
            'verification_status': 'pending',
            'billing_settings': paymentSetup,
            'campaign_preferences': {
              'targeting': targetingConfig,
              'budget': budgetAllocation,
            },
            'industry_targeting': targetingConfig,
            'total_budget_allocated': budgetAllocation['monthly_budget'],
            'is_active': true,
          })
          .select()
          .single();

      // Update onboarding record
      await _client
          .from('brand_onboarding')
          .update({
            'brand_account_id': brandAccount['id'],
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', onboardingId);

      return true;
    } catch (e) {
      debugPrint('Complete onboarding error: $e');
      return false;
    }
  }

  /// Get brand account for current user
  Future<Map<String, dynamic>?> getBrandAccount() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('brand_accounts')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get brand account error: $e');
      return null;
    }
  }

  /// Update brand account settings
  Future<bool> updateBrandAccount({
    required String brandAccountId,
    Map<String, dynamic>? billingSettings,
    Map<String, dynamic>? campaignPreferences,
    Map<String, dynamic>? industryTargeting,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (billingSettings != null) {
        updates['billing_settings'] = billingSettings;
      }
      if (campaignPreferences != null) {
        updates['campaign_preferences'] = campaignPreferences;
      }
      if (industryTargeting != null) {
        updates['industry_targeting'] = industryTargeting;
      }

      await _client
          .from('brand_accounts')
          .update(updates)
          .eq('id', brandAccountId);

      return true;
    } catch (e) {
      debugPrint('Update brand account error: $e');
      return false;
    }
  }

  /// Moderate sponsored election content with OpenAI
  Future<Map<String, dynamic>> moderateSponsoredContent({
    required String electionTitle,
    required String electionDescription,
    required List<String> options,
  }) async {
    try {
      // In production, call OpenAI moderation API
      // For now, return mock moderation result
      final content =
          '$electionTitle $electionDescription ${options.join(' ')}';

      // Simulate moderation check
      final hasViolations =
          content.toLowerCase().contains('spam') ||
          content.toLowerCase().contains('scam');

      return {
        'approved': !hasViolations,
        'status': hasViolations ? 'rejected' : 'approved',
        'violations': hasViolations
            ? ['Potential spam or misleading content detected']
            : [],
        'confidence_score': hasViolations ? 0.95 : 0.05,
        'moderated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Moderate sponsored content error: $e');
      return {
        'approved': false,
        'status': 'error',
        'violations': ['Moderation service unavailable'],
      };
    }
  }
}
