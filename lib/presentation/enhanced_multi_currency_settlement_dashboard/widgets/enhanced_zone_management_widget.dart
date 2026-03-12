import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/multi_currency_settlement_service.dart';
import '../../../theme/app_theme.dart';

class EnhancedZoneManagementWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> zoneStatus;
  final Map<String, String> complianceStatus;
  final VoidCallback onRefresh;

  const EnhancedZoneManagementWidget({
    super.key,
    required this.zoneStatus,
    required this.complianceStatus,
    required this.onRefresh,
  });

  static const Map<String, double> zoneMinimums = {
    'US_Canada': 50.0,
    'Western_Europe': 50.0,
    'Eastern_Europe': 25.0,
    'Africa': 10.0,
    'Latin_America': 20.0,
    'Middle_East_Asia': 30.0,
    'Australasia': 40.0,
    'China_Hong_Kong': 30.0,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: MultiCurrencySettlementService.zones.length,
        itemBuilder: (context, index) {
          final zone = MultiCurrencySettlementService.zones[index];
          final status = zoneStatus[zone];
          final compliance = complianceStatus[zone] ?? 'pending';
          final minimum = zoneMinimums[zone] ?? 50.0;

          return _buildZoneCard(theme, zone, status, compliance, minimum);
        },
      ),
    );
  }

  Widget _buildZoneCard(
    ThemeData theme,
    String zone,
    Map<String, dynamic>? status,
    String compliance,
    double minimum,
  ) {
    final zoneName = zone.replaceAll('_', ' ');
    final payoutStatus = status?['status'] ?? 'none';
    final amount = status?['amount'] ?? 0.0;

    Color statusColor;
    IconData statusIcon;
    switch (payoutStatus) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'processing':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'pending':
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle_outline;
    }

    Color complianceColor;
    IconData complianceIcon;
    switch (compliance) {
      case 'approved':
        complianceColor = Colors.green;
        complianceIcon = Icons.verified;
        break;
      case 'rejected':
        complianceColor = Colors.red;
        complianceIcon = Icons.cancel;
        break;
      default:
        complianceColor = Colors.orange;
        complianceIcon = Icons.pending;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public, color: AppTheme.primaryLight, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  zoneName,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(complianceIcon, color: complianceColor, size: 5.w),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minimum Threshold',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '\$${minimum.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Last Payout',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 4.w),
              SizedBox(width: 2.w),
              Text(
                'Status: ${payoutStatus.toUpperCase()}',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
