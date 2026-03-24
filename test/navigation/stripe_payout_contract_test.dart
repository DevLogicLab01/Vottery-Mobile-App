import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Stripe payout - Web/Mobile contract', () {
    test('stripe/payout web URLs stay aligned', () {
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
        AppUrls.enhancedCreatorPayoutDashboard,
        endsWith('/enhanced-creator-payout-dashboard-with-stripe-connect-integration'),
      );
      expect(
        AppUrls.internationalPaymentDisputeResolution,
        endsWith('/international-payment-dispute-resolution-center'),
      );
    });

    test('route registry keeps payment/settlement canonical mappings', () {
      expect(
        screenForRoute(AppRoutes.unifiedPaymentOrchestrationHubWebCanonical)
            .runtimeType
            .toString(),
        'UnifiedPaymentOrchestrationHub',
      );
      expect(
        screenForRoute(AppRoutes.multiCurrencySettlementDashboardWebCanonical)
            .runtimeType
            .toString(),
        'MultiCurrencySettlementDashboard',
      );
      expect(
        screenForRoute(
          AppRoutes.enhancedMultiCurrencySettlementDashboardWebCanonical,
        ).runtimeType.toString(),
        'EnhancedMultiCurrencySettlementDashboard',
      );
    });
  });
}
