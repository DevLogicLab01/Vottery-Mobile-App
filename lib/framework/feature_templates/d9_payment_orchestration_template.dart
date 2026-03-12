import '../shared_constants.dart';

/// D9 - Unified Payment Orchestration Template
class PaymentOrchestrationTemplate {
  PaymentOrchestrationTemplate._();

  static String getRoutePath() => SharedConstants.unifiedPaymentOrchestration;
  static String getPayoutTable() => SharedConstants.payoutSettings;
  static String getPaymentMethodsTable() => SharedConstants.userPaymentMethods;

  static List<String> getPaymentFlows() => [
    'subscription_payment',
    'participation_fee',
    'creator_payout',
  ];

  static Map<String, String> getPaymentProviders() => {
    'subscription': 'Stripe',
    'participation_fee': 'Stripe',
    'creator_payout': 'Stripe Connect / PayPal',
  };

  static String getImplementationGuide() =>
      '''
D9 - Payment Orchestration Implementation Guide:
1. Route: ${getRoutePath()}
2. Tables: ${getPayoutTable()}, ${getPaymentMethodsTable()}
3. Payment flows: ${getPaymentFlows().join(', ')}
4. Providers: ${getPaymentProviders()}
5. Reuse: stripe_connect_service.dart, payout_management_service.dart
''';
}
