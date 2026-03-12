import '../shared_constants.dart';

/// D11 - Constants Sync Validation Template
/// Ensures Web and Mobile constants remain synchronized.
class ConstantsSyncTemplate {
  ConstantsSyncTemplate._();

  /// All constants that must match between Web and Mobile
  static Map<String, String> getSharedConstantsMap() => {
    // Database Tables
    'sponsored_elections': SharedConstants.sponsoredElections,
    'platform_gamification_campaigns':
        SharedConstants.platformGamificationCampaigns,
    'user_vp_transactions': SharedConstants.userVpTransactions,
    'feature_requests': SharedConstants.featureRequests,
    'elections': SharedConstants.electionsTable,
    'payout_settings': SharedConstants.payoutSettings,
    'user_subscriptions': SharedConstants.userSubscriptions,
    'user_payment_methods': SharedConstants.userPaymentMethods,
    // Stripe Products
    'prod_basic_vp_2x': SharedConstants.stripeProductBasic,
    'prod_pro_vp_3x': SharedConstants.stripeProductPro,
    'prod_elite_vp_5x': SharedConstants.stripeProductElite,
    // Error Codes
    'PAYMENT_FAILED': SharedConstants.paymentFailed,
    'SUBSCRIPTION_EXPIRED': SharedConstants.subscriptionExpired,
    'INSUFFICIENT_VP': SharedConstants.insufficientVp,
    // Edge Functions
    'stripe-secure-proxy': SharedConstants.stripeSecureProxy,
    'send-compliance-report': SharedConstants.sendComplianceReport,
    'prediction_pool_webhooks': SharedConstants.predictionPoolWebhooks,
    'user_activity_analyzer': SharedConstants.userActivityAnalyzer,
    // Election Columns
    'allow_comments': SharedConstants.allowComments,
    'is_gamified': SharedConstants.isGamified,
    'prize_config': SharedConstants.prizeConfig,
  };

  static List<String> getValidationRules() => [
    'All table names must match exactly between Web and Mobile',
    'Route paths must use kebab-case and match Web routes',
    'Stripe product IDs must be identical across platforms',
    'VP multipliers must be consistent: Basic=2x, Pro=3x, Elite=5x',
    'Error codes must be uppercase with underscores',
    'Edge function names must match Supabase deployment names',
    'Column names must match Supabase schema exactly',
  ];

  static String getImplementationGuide() =>
      '''
D11 - Constants Sync Implementation Guide:
1. Single source: lib/framework/shared_constants.dart
2. All features import SharedConstants instead of hardcoding values
3. Validation: WebMobileSyncValidator.validateConstants()
4. Pre-commit: scripts/validate_web_mobile_sync.sh
5. CI/CD: .github/workflows/flutter-ci-enhanced.yml validation step
6. Total shared constants: ${getSharedConstantsMap().length}
''';
}
