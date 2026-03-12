import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class PayoutMethodCardWidget extends StatelessWidget {
  final Map<String, dynamic>? payoutSettings;
  final VoidCallback onAddPayout;
  final VoidCallback onManage;

  const PayoutMethodCardWidget({
    super.key,
    this.payoutSettings,
    required this.onAddPayout,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSettings = payoutSettings != null;
    final stripeConnected =
        payoutSettings?['stripe_connect_status'] == 'active';
    final bankLast4 = payoutSettings?['bank_last4'] as String?;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(20),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Creator Payout Methods',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          // Stripe Connect Status
          _PayoutRow(
            icon: Icons.payment,
            label: 'Stripe Connect',
            value: stripeConnected ? 'Connected' : 'Not Connected',
            valueColor: stripeConnected
                ? const Color(0xFF22C55E)
                : Colors.orange,
          ),
          if (bankLast4 != null) ...[
            SizedBox(height: 0.5.h),
            _PayoutRow(
              icon: Icons.account_balance,
              label: 'Bank Account',
              value: '•••• $bankLast4',
              valueColor: const Color(0xFF6366F1),
            ),
          ],
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Manage'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddPayout,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Method'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _PayoutRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 4.w, color: Colors.grey.shade500),
        SizedBox(width: 2.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
