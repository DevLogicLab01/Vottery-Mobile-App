import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// E2E tests for payment processing: navigate to wallet/payment, initiate flow,
/// verify payment/Stripe UI. Used by CI for critical user flow validation.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Payment Processing E2E', () {
    testWidgets('User can initiate payment flow', (tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final walletButton = find.byKey(const Key('wallet_nav_button'));
      if (walletButton.evaluate().isNotEmpty) {
        await tester.tap(walletButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final payButton = find.byKey(const Key('payment_button'));
      if (payButton.evaluate().isNotEmpty) {
        await tester.tap(payButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final paymentUI = find.byKey(const Key('payment_form'));
      final stripeUI = find.textContaining('Stripe');
      expect(
        paymentUI.evaluate().isNotEmpty || stripeUI.evaluate().isNotEmpty,
        isTrue,
        reason: 'Payment UI should be accessible',
      );
    });
  });
}
