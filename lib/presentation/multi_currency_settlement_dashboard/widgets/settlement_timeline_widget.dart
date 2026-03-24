import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/multi_currency_settlement_service.dart';

class SettlementTimelineWidget extends StatelessWidget {
  const SettlementTimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settlement Timeline',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: MultiCurrencySettlementService.settlementTimelines.entries
                .map(
                  (entry) => _buildTimelineRow(entry.key, entry.value, theme),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow(
    String paymentMethod,
    String timeline,
    ThemeData theme,
  ) {
    IconData icon;
    Color color;

    switch (paymentMethod) {
      case 'PayPal':
        icon = Icons.flash_on;
        color = Colors.blue;
        break;
      case 'Stripe':
        icon = Icons.credit_card;
        color = Colors.purple;
        break;
      case 'bank_transfer':
        icon = Icons.account_balance;
        color = Colors.green;
        break;
      default:
        icon = Icons.payment;
        color = Colors.grey;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paymentMethod.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Processing time: $timeline',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
            size: 5.w,
          ),
        ],
      ),
    );
  }
}
