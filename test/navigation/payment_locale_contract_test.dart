import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/presentation/automated_payment_processing_hub/automated_payment_processing_hub.dart';
import 'package:vottery/presentation/participation_fee_payment/participation_fee_payment_screen.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Payment and localization - Web/Mobile contract', () {
    test('payment/localization web URLs stay aligned', () {
      expect(
        AppUrls.stripePaymentIntegrationHub,
        endsWith('/stripe-payment-integration-hub'),
      );
      expect(
        AppUrls.automatedPaymentProcessingHub,
        endsWith('/automated-payment-processing-hub'),
      );
      expect(
        AppUrls.internationalPaymentDisputeResolution,
        endsWith('/international-payment-dispute-resolution-center'),
      );
      expect(
        AppUrls.localizationTaxReportingIntelligenceCenter,
        endsWith('/localization-tax-reporting-intelligence-center'),
      );
      expect(
        AppUrls.gamificationMultiLanguageIntelligenceCenter,
        endsWith('/gamification-multi-language-intelligence-center'),
      );
    });

    test('payment routes resolve to expected native screens', () {
      expect(
        screenForRoute(AppRoutes.automatedPaymentProcessingHub),
        isA<AutomatedPaymentProcessingHub>(),
      );
      expect(
        screenForRoute(AppRoutes.participationFeePayment),
        isA<ParticipationFeePaymentScreen>(),
      );
    });
  });
}
