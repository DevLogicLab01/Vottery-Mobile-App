import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class SubscriptionPaymentCardWidget extends StatelessWidget {
  final Map<String, dynamic>? paymentMethod;
  final VoidCallback onAddMethod;
  final VoidCallback onManage;

  const SubscriptionPaymentCardWidget({
    super.key,
    this.paymentMethod,
    required this.onAddMethod,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMethod = paymentMethod != null;
    final brand = paymentMethod?['brand'] as String? ?? 'Visa';
    final last4 = paymentMethod?['last4'] as String? ?? '****';
    final expMonth = paymentMethod?['exp_month']?.toString() ?? '--';
    final expYear = paymentMethod?['exp_year']?.toString() ?? '--';

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
                  color: const Color(0xFF6366F1).withAlpha(20),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Subscription Payment',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: hasMethod
                      ? const Color(0xFF22C55E).withAlpha(20)
                      : Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  hasMethod ? 'Active' : 'Not Set',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: hasMethod ? const Color(0xFF22C55E) : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          if (hasMethod) ...[
            Row(
              children: [
                Text(
                  '$brand •••• $last4',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  'Exp $expMonth/$expYear',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManage,
                    icon: const Icon(Icons.manage_accounts, size: 16),
                    label: const Text('Manage'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAddMethod,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No payment method configured for subscriptions.',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 1.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddMethod,
                icon: const Icon(Icons.add_card),
                label: const Text('Add Payment Method'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
