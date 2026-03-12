import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/multi_currency_settlement_service.dart';

class ZoneOverviewWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> zoneStatus;
  final Map<String, String> complianceStatus;

  const ZoneOverviewWidget({
    super.key,
    required this.zoneStatus,
    required this.complianceStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zone Overview',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 1.5,
          ),
          itemCount: MultiCurrencySettlementService.zones.length,
          itemBuilder: (context, index) {
            final zone = MultiCurrencySettlementService.zones[index];
            final status = zoneStatus[zone];
            final compliance = complianceStatus[zone] ?? 'unknown';

            return _buildZoneCard(zone, status, compliance, theme);
          },
        ),
      ],
    );
  }

  Widget _buildZoneCard(
    String zone,
    Map<String, dynamic>? status,
    String compliance,
    ThemeData theme,
  ) {
    final payoutStatus = status?['status'] ?? 'none';
    Color statusColor;

    switch (payoutStatus) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'failed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: statusColor.withAlpha(77), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  zone.replaceAll('_', ' '),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 2.w,
                height: 2.w,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payoutStatus.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Icon(
                    compliance == 'approved'
                        ? Icons.check_circle
                        : Icons.pending,
                    size: 3.w,
                    color: compliance == 'approved'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    compliance.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
