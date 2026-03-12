import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class RedemptionOptionsWidget extends StatelessWidget {
  final Map<String, dynamic> vpBalance;
  final Map<String, dynamic>? verificationStatus;
  final VoidCallback onRedemptionComplete;

  const RedemptionOptionsWidget({
    super.key,
    required this.vpBalance,
    required this.verificationStatus,
    required this.onRedemptionComplete,
  });

  @override
  Widget build(BuildContext context) {
    final availableVP = (vpBalance['available_vp'] ?? 0) as int;
    final isVerified = verificationStatus?['verification_status'] == 'approved';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Redemption Options',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildRedemptionCard(
            context,
            title: 'Cash Redemption',
            subtitle: 'Minimum \$10 = 2,000 VP | 2-3 business days',
            icon: Icons.account_balance,
            color: AppTheme.accentLight,
            minVP: 2000,
            availableVP: availableVP,
            isVerified: isVerified,
            onTap: () =>
                _showCashRedemptionDialog(context, availableVP, isVerified),
          ),
          SizedBox(height: 2.h),
          _buildRedemptionCard(
            context,
            title: 'Gift Cards',
            subtitle: 'Amazon, Starbucks, iTunes, Google Play | 1,000 VP = \$5',
            icon: Icons.card_giftcard,
            color: Colors.orange,
            minVP: 1000,
            availableVP: availableVP,
            isVerified: true, // Gift cards don't require verification
            onTap: () => _showGiftCardDialog(context, availableVP),
          ),
          SizedBox(height: 2.h),
          _buildRedemptionCard(
            context,
            title: 'Crypto Redemption (USDC)',
            subtitle:
                'Stablecoin conversion | 1-2 hours | Current rate: 1 VP = \$0.005',
            icon: Icons.currency_bitcoin,
            color: AppTheme.secondaryLight,
            minVP: 2000,
            availableVP: availableVP,
            isVerified: isVerified,
            onTap: () =>
                _showCryptoRedemptionDialog(context, availableVP, isVerified),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int minVP,
    required int availableVP,
    required bool isVerified,
    required VoidCallback onTap,
  }) {
    final canRedeem = availableVP >= minVP && isVerified;

    return InkWell(
      onTap: canRedeem ? onTap : null,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: canRedeem ? color : Colors.grey.shade300,
            width: 2.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(77),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isVerified && minVP > 1000)
                    Padding(
                      padding: EdgeInsets.only(top: 0.5.h),
                      child: Text(
                        'KYC verification required',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: AppTheme.warningLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: canRedeem ? color : Colors.grey.shade400,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _showCashRedemptionDialog(
    BuildContext context,
    int availableVP,
    bool isVerified,
  ) {
    if (!isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete KYC verification to redeem cash'),
          backgroundColor: AppTheme.warningLight,
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cash Redemption via Bank Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: $availableVP VP',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'VP Amount',
                hintText: 'Minimum 2,000 VP',
                border: OutlineInputBorder(),
                suffixText: 'VP',
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Conversion: 2,000 VP = \$10 USD',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(amountController.text) ?? 0;
              if (amount >= 2000 && amount <= availableVP) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cash redemption request submitted'),
                    backgroundColor: AppTheme.accentLight,
                  ),
                );
                onRedemptionComplete();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid amount. Minimum 2,000 VP required.'),
                    backgroundColor: AppTheme.errorLight,
                  ),
                );
              }
            },
            child: Text('Redeem Now'),
          ),
        ],
      ),
    );
  }

  void _showGiftCardDialog(BuildContext context, int availableVP) {
    final providers = ['Amazon', 'Starbucks', 'iTunes', 'Google Play'];
    String selectedProvider = providers[0];
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Gift Card Redemption'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available: $availableVP VP',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                initialValue: selectedProvider,
                decoration: InputDecoration(
                  labelText: 'Provider',
                  border: OutlineInputBorder(),
                ),
                items: providers
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedProvider = value!);
                },
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'VP Amount',
                  hintText: 'Minimum 1,000 VP',
                  border: OutlineInputBorder(),
                  suffixText: 'VP',
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Conversion: 1,000 VP = \$5 gift card',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = int.tryParse(amountController.text) ?? 0;
                if (amount >= 1000 && amount <= availableVP) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$selectedProvider gift card redemption submitted',
                      ),
                      backgroundColor: AppTheme.accentLight,
                    ),
                  );
                  onRedemptionComplete();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Invalid amount. Minimum 1,000 VP required.',
                      ),
                      backgroundColor: AppTheme.errorLight,
                    ),
                  );
                }
              },
              child: Text('Redeem Now'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCryptoRedemptionDialog(
    BuildContext context,
    int availableVP,
    bool isVerified,
  ) {
    if (!isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete KYC verification to redeem crypto'),
          backgroundColor: AppTheme.warningLight,
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    final walletController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crypto Redemption (USDC)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: $availableVP VP',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'VP Amount',
                hintText: 'Minimum 2,000 VP',
                border: OutlineInputBorder(),
                suffixText: 'VP',
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: walletController,
              decoration: InputDecoration(
                labelText: 'USDC Wallet Address',
                hintText: '0x...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Current rate: 1 VP = \$0.005 USDC',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(amountController.text) ?? 0;
              if (amount >= 2000 &&
                  amount <= availableVP &&
                  walletController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Crypto redemption request submitted'),
                    backgroundColor: AppTheme.accentLight,
                  ),
                );
                onRedemptionComplete();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid amount or wallet address'),
                    backgroundColor: AppTheme.errorLight,
                  ),
                );
              }
            },
            child: Text('Redeem Now'),
          ),
        ],
      ),
    );
  }
}
