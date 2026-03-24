import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/constants/app_urls.dart';

/// Contract tests: Mobile Web launcher URLs must match Vottery Web React routes.
void main() {
  group('AppUrls Web parity', () {
    test('international payment disputes path', () {
      expect(
        AppUrls.internationalPaymentDisputeResolution,
        contains('/international-payment-dispute-resolution-center'),
      );
      expect(
        AppUrls.claudeDisputeResolution,
        AppUrls.internationalPaymentDisputeResolution,
      );
    });

    test('admin subscription & Stripe hubs', () {
      expect(
        AppUrls.adminSubscriptionAnalyticsHub,
        endsWith('/admin-subscription-analytics-hub'),
      );
      expect(
        AppUrls.stripeSubscriptionManagementCenter,
        endsWith('/stripe-subscription-management-center'),
      );
      expect(
        AppUrls.stripePaymentIntegrationHub,
        endsWith('/stripe-payment-integration-hub'),
      );
      expect(
        AppUrls.automatedPayoutCalculationEngine,
        endsWith('/automated-payout-calculation-engine'),
      );
      expect(
        AppUrls.countryBasedPayoutProcessingEngine,
        endsWith('/country-based-payout-processing-engine'),
      );
      expect(
        AppUrls.adminQuestConfigurationControlCenter,
        endsWith('/admin-quest-configuration-control-center'),
      );
    });

    test('gamification Web paths', () {
      expect(
        AppUrls.comprehensiveGamificationAdminControlCenter,
        endsWith('/comprehensive-gamification-admin-control-center'),
      );
      expect(
        AppUrls.platformGamificationCoreEngine,
        endsWith('/platform-gamification-core-engine'),
      );
      expect(
        AppUrls.gamificationCampaignManagementCenter,
        endsWith('/gamification-campaign-management-center'),
      );
      expect(
        AppUrls.gamificationRewardsManagementCenter,
        endsWith('/gamification-rewards-management-center'),
      );
    });

    test('compliance & transparency paths', () {
      expect(
        AppUrls.securityComplianceAutomationCenter,
        endsWith('/security-compliance-automation-center'),
      );
      expect(
        AppUrls.localizationTaxReportingIntelligenceCenter,
        endsWith('/localization-tax-reporting-intelligence-center'),
      );
      expect(AppUrls.complianceDashboard, endsWith('/compliance-dashboard'));
      expect(
        AppUrls.complianceAuditDashboard,
        endsWith('/compliance-audit-dashboard'),
      );
      expect(
        AppUrls.regulatoryComplianceAutomationHub,
        endsWith('/regulatory-compliance-automation-hub'),
      );
      expect(
        AppUrls.publicBulletinBoardAuditTrailCenter,
        endsWith('/public-bulletin-board-audit-trail-center'),
      );
      expect(
        AppUrls.cryptographicSecurityManagementCenter,
        endsWith('/cryptographic-security-management-center'),
      );
      expect(
        AppUrls.voteAnonymityMixnetControlHub,
        endsWith('/vote-anonymity-mixnet-control-hub'),
      );
      expect(
        AppUrls.voteVerificationPortal,
        endsWith('/vote-verification-portal'),
      );
    });

    test('Claude dispute moderation path (distinct from intl disputes)', () {
      expect(
        AppUrls.claudeAiDisputeModerationCenter,
        endsWith('/claude-ai-dispute-moderation-center'),
      );
      expect(
        AppUrls.claudeAiDisputeModerationCenter,
        isNot(equals(AppUrls.internationalPaymentDisputeResolution)),
      );
    });
  });
}
