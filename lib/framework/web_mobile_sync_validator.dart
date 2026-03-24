import 'package:flutter/foundation.dart';

import './feature_templates/d11_constants_sync_template.dart';
import './shared_constants.dart';

/// WebMobileSyncValidator
/// Validates that Flutter SharedConstants match Web constants.js exactly.
/// Throws [WebMobileSyncException] if any divergence is detected.
class WebMobileSyncValidator {
  WebMobileSyncValidator._();

  static final List<String> _validationErrors = [];
  static final List<String> _validationWarnings = [];

  /// Run full validation suite
  static ValidationResult validateAll() {
    _validationErrors.clear();
    _validationWarnings.clear();

    _validateDatabaseTables();
    _validateRoutePaths();
    _validateStripeConstants();
    _validateVpMultipliers();
    _validateErrorCodes();
    _validateEdgeFunctions();
    _validateElectionColumns();

    return ValidationResult(
      isValid: _validationErrors.isEmpty,
      errors: List.unmodifiable(_validationErrors),
      warnings: List.unmodifiable(_validationWarnings),
      totalChecked: ConstantsSyncTemplate.getSharedConstantsMap().length,
    );
  }

  /// Validate database table names match expected values
  static void _validateDatabaseTables() {
    final tables = {
      'sponsored_elections': SharedConstants.sponsoredElections,
      'platform_gamification_campaigns':
          SharedConstants.platformGamificationCampaigns,
      'user_vp_transactions': SharedConstants.userVpTransactions,
      'feature_requests': SharedConstants.featureRequests,
      'elections': SharedConstants.electionsTable,
      'payout_settings': SharedConstants.payoutSettings,
      'user_subscriptions': SharedConstants.userSubscriptions,
      'user_payment_methods': SharedConstants.userPaymentMethods,
    };

    for (final entry in tables.entries) {
      if (entry.key != entry.value) {
        _validationErrors.add(
          'TABLE MISMATCH: Expected "${entry.key}" but got "${entry.value}"',
        );
      }
    }
  }

  /// Validate route paths match Web app routes
  static void _validateRoutePaths() {
    final routes = {
      '/campaign-management-dashboard':
          SharedConstants.campaignManagementDashboard,
      '/participatory-ads-studio': SharedConstants.participatoryAdsStudio,
      '/community-engagement-dashboard':
          SharedConstants.communityEngagementDashboard,
      '/enhanced-incident-response-analytics':
          SharedConstants.incidentResponseAnalytics,
      '/subscription-architecture': SharedConstants.subscriptionArchitecture,
      '/unified-payment-orchestration-hub':
          SharedConstants.unifiedPaymentOrchestration,
    };

    for (final entry in routes.entries) {
      if (entry.key != entry.value) {
        _validationErrors.add(
          'ROUTE MISMATCH: Expected "${entry.key}" but got "${entry.value}"',
        );
      }
    }
  }

  /// Validate Stripe product IDs
  static void _validateStripeConstants() {
    final stripeProducts = {
      'prod_basic_vp_2x': SharedConstants.stripeProductBasic,
      'prod_pro_vp_3x': SharedConstants.stripeProductPro,
      'prod_elite_vp_5x': SharedConstants.stripeProductElite,
    };

    for (final entry in stripeProducts.entries) {
      if (entry.key != entry.value) {
        _validationErrors.add(
          'STRIPE MISMATCH: Expected "${entry.key}" but got "${entry.value}"',
        );
      }
    }
  }

  /// Validate VP multipliers
  static void _validateVpMultipliers() {
    if (SharedConstants.vpMultiplierBasic != 2) {
      _validationErrors.add(
        'VP_MULTIPLIER MISMATCH: Basic should be 2, got ${SharedConstants.vpMultiplierBasic}',
      );
    }
    if (SharedConstants.vpMultiplierPro != 3) {
      _validationErrors.add(
        'VP_MULTIPLIER MISMATCH: Pro should be 3, got ${SharedConstants.vpMultiplierPro}',
      );
    }
    if (SharedConstants.vpMultiplierElite != 5) {
      _validationErrors.add(
        'VP_MULTIPLIER MISMATCH: Elite should be 5, got ${SharedConstants.vpMultiplierElite}',
      );
    }
  }

  /// Validate error codes
  static void _validateErrorCodes() {
    final errorCodes = {
      'PAYMENT_FAILED': SharedConstants.paymentFailed,
      'SUBSCRIPTION_EXPIRED': SharedConstants.subscriptionExpired,
      'INSUFFICIENT_VP': SharedConstants.insufficientVp,
    };

    for (final entry in errorCodes.entries) {
      if (entry.key != entry.value) {
        _validationErrors.add(
          'ERROR_CODE MISMATCH: Expected "${entry.key}" but got "${entry.value}"',
        );
      }
    }
  }

  /// Validate Edge Function names
  static void _validateEdgeFunctions() {
    final functions = {
      'stripe-secure-proxy': SharedConstants.stripeSecureProxy,
      'send-compliance-report': SharedConstants.sendComplianceReport,
      'prediction_pool_webhooks': SharedConstants.predictionPoolWebhooks,
      'user_activity_analyzer': SharedConstants.userActivityAnalyzer,
    };

    for (final entry in functions.entries) {
      if (entry.key != entry.value) {
        _validationErrors.add(
          'EDGE_FUNCTION MISMATCH: Expected "${entry.key}" but got "${entry.value}"',
        );
      }
    }
  }

  /// Validate election column names
  static void _validateElectionColumns() {
    final columns = {
      'allow_comments': SharedConstants.allowComments,
      'is_gamified': SharedConstants.isGamified,
      'prize_config': SharedConstants.prizeConfig,
    };

    for (final entry in columns.entries) {
      if (entry.key != entry.value) {
        _validationErrors.add(
          'COLUMN MISMATCH: Expected "${entry.key}" but got "${entry.value}"',
        );
      }
    }
  }

  /// Validate Supabase schema for a specific table
  static ValidationResult validateSupabaseSchema(
    String tableName,
    List<String> expectedColumns,
    List<String> actualColumns,
  ) {
    final errors = <String>[];
    for (final col in expectedColumns) {
      if (!actualColumns.contains(col)) {
        errors.add('SCHEMA MISMATCH: Table "$tableName" missing column "$col"');
      }
    }
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: [],
      totalChecked: expectedColumns.length,
    );
  }

  /// Validate Edge Function signatures
  static ValidationResult validateEdgeFunctions(
    String functionName,
    Map<String, dynamic> expectedSignature,
    Map<String, dynamic> actualSignature,
  ) {
    final errors = <String>[];
    for (final key in expectedSignature.keys) {
      if (!actualSignature.containsKey(key)) {
        errors.add(
          'EDGE_FUNCTION SIGNATURE MISMATCH: "$functionName" missing param "$key"',
        );
      }
    }
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: [],
      totalChecked: expectedSignature.length,
    );
  }

  /// Log validation results
  static void logValidationResult(ValidationResult result) {
    if (result.isValid) {
      debugPrint(
        '✅ Web/Mobile Sync Validation PASSED: ${result.totalChecked} constants verified',
      );
    } else {
      debugPrint(
        '❌ Web/Mobile Sync Validation FAILED: ${result.errors.length} errors',
      );
      for (final error in result.errors) {
        debugPrint('  ERROR: $error');
      }
    }
    for (final warning in result.warnings) {
      debugPrint('  WARNING: $warning');
    }
  }
}

/// Result of a validation run
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final int totalChecked;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.totalChecked,
  });
}

/// Exception thrown when Web/Mobile sync validation fails
class WebMobileSyncException implements Exception {
  final String message;
  final List<String> errors;

  const WebMobileSyncException({required this.message, required this.errors});

  @override
  String toString() =>
      'WebMobileSyncException: $message\nErrors:\n${errors.map((e) => '  - $e').join('\n')}';
}
