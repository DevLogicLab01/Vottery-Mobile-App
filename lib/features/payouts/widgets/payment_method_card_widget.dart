import 'package:flutter/material.dart';

/// YouTube-style: Single payment method. Link to settings if not set.
class PaymentMethodCardWidget extends StatelessWidget {
  const PaymentMethodCardWidget({super.key, this.settings});

  final Map<String, dynamic>? settings;

  @override
  Widget build(BuildContext context) {
    final method = settings?['preferred_method'] ?? 'bank_transfer';
    final bankDetails = settings?['bank_details'] as Map<String, dynamic>?;
    final hasBank = method == 'bank_transfer' && bankDetails?['account_name'] != null;
    final hasStripe = method == 'stripe' && settings?['stripe_account_id'] != null;
    final isSet = hasBank || hasStripe;

    final label = method == 'bank_transfer'
        ? 'Bank account'
        : method == 'stripe'
            ? 'Stripe Connect'
            : 'Payment method';

    String subtitle = 'Not set';
    if (isSet && method == 'bank_transfer' && bankDetails?['account_number'] != null) {
      final num = bankDetails!['account_number'].toString();
      subtitle = '•••• ${num.length >= 4 ? num.substring(num.length - 4) : num}';
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment method',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSet ? '$label $subtitle' : label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text(isSet ? 'Manage' : 'Add payment method'),
            ),
          ],
        ),
      ),
    );
  }
}
