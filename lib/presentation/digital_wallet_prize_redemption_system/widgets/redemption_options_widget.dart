import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RedemptionOptionsWidget extends StatefulWidget {
  final double availableBalance;
  final String currency;
  final Function(double amount, String method) onRedeemCash;
  final Function(double amount, String provider) onRedeemGiftCard;

  const RedemptionOptionsWidget({
    super.key,
    required this.availableBalance,
    required this.currency,
    required this.onRedeemCash,
    required this.onRedeemGiftCard,
  });

  @override
  State<RedemptionOptionsWidget> createState() =>
      _RedemptionOptionsWidgetState();
}

class _RedemptionOptionsWidgetState extends State<RedemptionOptionsWidget> {
  String _selectedMethod = 'cash';
  final TextEditingController _amountController = TextEditingController();
  String _selectedGiftCardProvider = 'amazon';
  String _selectedCryptoMethod = 'stripe';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Redemption Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),

          // Method selector
          Row(
            children: [
              Expanded(
                child: _buildMethodButton(
                  label: 'Cash',
                  icon: Icons.account_balance,
                  method: 'cash',
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMethodButton(
                  label: 'Gift Card',
                  icon: Icons.card_giftcard,
                  method: 'gift_card',
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Redemption form
          if (_selectedMethod == 'cash') _buildCashRedemption(),
          if (_selectedMethod == 'gift_card') _buildGiftCardRedemption(),
        ],
      ),
    );
  }

  Widget _buildMethodButton({
    required String label,
    required IconData icon,
    required String method,
  }) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24.sp,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashRedemption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank Transfer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Minimum: \$10 | Processing: 2-3 business days',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        SizedBox(height: 2.h),

        // Payment method selector
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodCard(
                label: 'Stripe',
                icon: Icons.credit_card,
                method: 'stripe',
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildPaymentMethodCard(
                label: 'Trolley',
                icon: Icons.account_balance_wallet,
                method: 'trolley',
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Amount input
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '\$',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // Redeem button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text) ?? 0.0;
              if (amount >= 10 && amount <= widget.availableBalance) {
                widget.onRedeemCash(amount, _selectedCryptoMethod);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Request Payout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGiftCardRedemption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gift Card Redemption',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Minimum: \$5 | Instant delivery | 1000 VP = \$5',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        SizedBox(height: 2.h),

        // Gift card provider selector
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: [
            _buildGiftCardProviderChip('Amazon', 'amazon'),
            _buildGiftCardProviderChip('Starbucks', 'starbucks'),
            _buildGiftCardProviderChip('iTunes', 'itunes'),
            _buildGiftCardProviderChip('Google Play', 'google_play'),
          ],
        ),
        SizedBox(height: 2.h),

        // Amount input
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '\$',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // Redeem button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text) ?? 0.0;
              if (amount >= 5 && amount <= widget.availableBalance) {
                widget.onRedeemGiftCard(amount, _selectedGiftCardProvider);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Redeem Gift Card',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String label,
    required IconData icon,
    required String method,
  }) {
    final isSelected = _selectedCryptoMethod == method;

    return GestureDetector(
      onTap: () => setState(() => _selectedCryptoMethod = method),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withAlpha(26) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 24.sp,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftCardProviderChip(String label, String provider) {
    final isSelected = _selectedGiftCardProvider == provider;

    return GestureDetector(
      onTap: () => setState(() => _selectedGiftCardProvider = provider),
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? Colors.green : Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
