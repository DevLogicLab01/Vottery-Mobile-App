import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class DataRetentionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> policies;

  const DataRetentionWidget({super.key, required this.policies});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Retention Policies',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Automated data purging based on legal retention requirements',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
            SizedBox(height: 2.h),
            if (policies.isEmpty)
              Center(
                child: Text(
                  'No retention policies configured',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              )
            else
              ...policies.map((policy) => _buildPolicyRow(context, policy)),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyRow(BuildContext context, Map<String, dynamic> policy) {
    final theme = Theme.of(context);
    final dataCategory = policy['data_category'] as String? ?? 'Unknown';
    final retentionDays = policy['retention_period_days'] as int? ?? 0;
    final autoPurgeEnabled = policy['auto_purge_enabled'] as bool? ?? false;
    final legalBasis = policy['legal_basis'] as String?;

    final retentionYears = (retentionDays / 365).toStringAsFixed(1);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dataCategory.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: autoPurgeEnabled
                      ? Colors.green.withAlpha(26)
                      : Colors.grey.withAlpha(26),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  autoPurgeEnabled ? 'AUTO-PURGE' : 'MANUAL',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: autoPurgeEnabled ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Retention: $retentionYears years ($retentionDays days)',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (legalBasis != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              legalBasis,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
