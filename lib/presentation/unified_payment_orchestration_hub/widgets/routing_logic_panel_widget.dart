import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class RoutingLogicPanelWidget extends StatelessWidget {
  final Map<String, dynamic>? preferences;
  final Function(String flow, String method) onUpdatePreference;

  const RoutingLogicPanelWidget({
    super.key,
    this.preferences,
    required this.onUpdatePreference,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  color: const Color(0xFF8B5CF6).withAlpha(20),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.route,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Smart Routing Logic',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _RoutingRow(
            flow: 'Subscription',
            icon: Icons.subscriptions,
            method: preferences?['subscription_method'] as String? ?? 'Stripe',
            color: const Color(0xFF6366F1),
            onUpdate: (m) => onUpdatePreference('subscription', m),
          ),
          const Divider(height: 16),
          _RoutingRow(
            flow: 'Participation Fee',
            icon: Icons.how_to_vote,
            method: preferences?['participation_method'] as String? ?? 'Stripe',
            color: const Color(0xFF0EA5E9),
            onUpdate: (m) => onUpdatePreference('participation', m),
          ),
          const Divider(height: 16),
          _RoutingRow(
            flow: 'Creator Payout',
            icon: Icons.account_balance,
            method:
                preferences?['payout_method'] as String? ?? 'Stripe Connect',
            color: const Color(0xFF10B981),
            onUpdate: (m) => onUpdatePreference('payout', m),
          ),
        ],
      ),
    );
  }
}

class _RoutingRow extends StatelessWidget {
  final String flow;
  final IconData icon;
  final String method;
  final Color color;
  final Function(String) onUpdate;

  const _RoutingRow({
    required this.flow,
    required this.icon,
    required this.method,
    required this.color,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 4.5.w),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                flow,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'via $method',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Text(
            method,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
