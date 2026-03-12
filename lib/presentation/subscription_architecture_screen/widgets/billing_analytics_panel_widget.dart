import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BillingAnalyticsPanelWidget extends StatelessWidget {
  final Map<String, dynamic>? subscription;

  const BillingAnalyticsPanelWidget({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextBilling = subscription?['next_billing_date'] as String?;
    final amount = (subscription?['amount'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = subscription?['payment_method'] as String? ?? 'card';
    final cardLast4 = subscription?['card_last4'] as String?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Billing Information',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            if (nextBilling != null)
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Next billing',
                value: _formatDate(nextBilling),
                theme: theme,
              ),
            if (amount > 0)
              _buildInfoRow(
                icon: Icons.attach_money,
                label: 'Amount',
                value: '\$${amount.toStringAsFixed(2)}',
                theme: theme,
              ),
            _buildInfoRow(
              icon: paymentMethod == 'paypal'
                  ? Icons.account_balance_wallet
                  : Icons.credit_card,
              label: 'Payment',
              value: cardLast4 != null
                  ? '•••• $cardLast4'
                  : paymentMethod == 'paypal'
                  ? 'PayPal'
                  : 'Card on file',
              theme: theme,
            ),
            if (subscription == null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Text(
                  'No active subscription found.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          SizedBox(width: 3.w),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.day}/${date.month}/${date.year}';
  }
}
