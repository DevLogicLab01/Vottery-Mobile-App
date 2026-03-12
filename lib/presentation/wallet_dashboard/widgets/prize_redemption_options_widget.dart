import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PrizeRedemptionOptionsWidget extends StatelessWidget {
  final double availableBalance;
  final Function(double amount) onRedeemCash;
  final Function(String provider, double amount) onRedeemGiftCard;

  const PrizeRedemptionOptionsWidget({
    super.key,
    required this.availableBalance,
    required this.onRedeemCash,
    required this.onRedeemGiftCard,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prize Redemption Options',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            _buildRedemptionOption(
              context,
              'Cash via Bank Transfer',
              'Minimum \$10 | 2-3 business days',
              Icons.account_balance,
              Colors.green,
              () => _showCashRedemptionDialog(context),
            ),
            SizedBox(height: 1.h),
            _buildRedemptionOption(
              context,
              'Gift Cards',
              'Amazon, Starbucks, iTunes, Google Play | 1000 VP = \$5',
              Icons.card_giftcard,
              Colors.orange,
              () => _showGiftCardDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedemptionOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32.sp),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18.sp),
          ],
        ),
      ),
    );
  }

  void _showCashRedemptionDialog(BuildContext context) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cash Redemption'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Available: \$${availableBalance.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (\$)',
                hintText: 'Minimum \$10',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount >= 10 && amount <= availableBalance) {
                Navigator.pop(context);
                onRedeemCash(amount);
              }
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  void _showGiftCardDialog(BuildContext context) {
    final providers = ['Amazon', 'Starbucks', 'iTunes', 'Google Play'];
    String selectedProvider = providers[0];
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gift Card Redemption'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedProvider,
              items: providers
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) => selectedProvider = value!,
              decoration: const InputDecoration(
                labelText: 'Provider',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (\$)',
                hintText: 'Minimum \$5',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount >= 5 && amount <= availableBalance) {
                Navigator.pop(context);
                onRedeemGiftCard(selectedProvider, amount);
              }
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

}
