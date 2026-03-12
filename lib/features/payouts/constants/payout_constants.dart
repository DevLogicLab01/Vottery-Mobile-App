/// Payout feature constants – must match Web (Source of Truth).
/// YouTube-style: threshold, monthly cycle, single payment method.

class PayoutConstants {
  PayoutConstants._();

  static const double payoutThreshold = 100.0;
  static const String defaultCurrency = 'USD';
  static const int payoutCycleDaySend = 21;
}

/// User-facing error messages – must match Web exactly.
class PayoutErrors {
  PayoutErrors._();

  static const String invalidAmount = 'Please enter a valid amount.';
  static const String insufficientBalance = 'Insufficient balance.';
  static String get belowThreshold =>
      'Minimum payout amount is \$${PayoutConstants.payoutThreshold.toInt()}.';
  static const String notAuthenticated =
      'You must be signed in to request a payout.';
  static const String requestFailed =
      'Unable to process payout. Please try again.';
  static const String paymentMethodRequired =
      'Add a payment method in settings to receive payouts.';
}

class PayoutSuccess {
  PayoutSuccess._();

  static const String requestSubmitted =
      'Payout request submitted. You\'ll be paid by the next payment date.';
}
