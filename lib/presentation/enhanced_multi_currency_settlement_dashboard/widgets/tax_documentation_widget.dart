import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TaxDocumentationWidget extends StatelessWidget {
  final Map<String, String> complianceStatus;

  const TaxDocumentationWidget({super.key, required this.complianceStatus});

  static const Map<String, String> taxRequirements = {
    'US_Canada': 'W-9 (US) or equivalent',
    'Western_Europe': 'VAT registration',
    'Eastern_Europe': 'W-8BEN',
    'Africa': 'W-8BEN',
    'Latin_America': 'W-8BEN',
    'Middle_East_Asia': 'W-8BEN',
    'Australasia': 'TFN declaration',
    'China_Hong_Kong': 'Tax residency certificate',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: taxRequirements.entries.map((entry) {
        final zone = entry.key;
        final requirement = entry.value;
        final status = complianceStatus[zone] ?? 'pending';

        return _buildTaxCard(theme, zone, requirement, status);
      }).toList(),
    );
  }

  Widget _buildTaxCard(
    ThemeData theme,
    String zone,
    String requirement,
    String status,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                zone.replaceAll('_', ' '),
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 5.w),
                  SizedBox(width: 2.w),
                  Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Required: $requirement',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
