import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class MultiJurisdictionMatrixWidget extends StatelessWidget {
  final List<Map<String, dynamic>> jurisdictions;

  const MultiJurisdictionMatrixWidget({super.key, required this.jurisdictions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final jurisdictionData = [
      {
        'code': 'US',
        'name': 'United States',
        'requirements': ['CCPA', 'State Privacy Laws'],
        'compliance': 92,
        'nextDeadline': 'Q2 2026 - Annual Report',
      },
      {
        'code': 'EU',
        'name': 'European Union',
        'requirements': ['GDPR', 'ePrivacy Directive'],
        'compliance': 95,
        'nextDeadline': 'Q1 2026 - DPO Report',
      },
      {
        'code': 'UK',
        'name': 'United Kingdom',
        'requirements': ['UK GDPR', 'Data Protection Act'],
        'compliance': 88,
        'nextDeadline': 'Q3 2026 - ICO Filing',
      },
      {
        'code': 'APAC',
        'name': 'Asia-Pacific',
        'requirements': ['PDPA', 'Privacy Act'],
        'compliance': 85,
        'nextDeadline': 'Q2 2026 - Regional Audit',
      },
      {
        'code': 'LATAM',
        'name': 'Latin America',
        'requirements': ['LGPD', 'Local Regulations'],
        'compliance': 90,
        'nextDeadline': 'Q4 2026 - Compliance Review',
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: jurisdictionData.length,
      itemBuilder: (context, index) {
        return _buildJurisdictionCard(context, jurisdictionData[index]);
      },
    );
  }

  Widget _buildJurisdictionCard(
    BuildContext context,
    Map<String, dynamic> jurisdiction,
  ) {
    final theme = Theme.of(context);
    final compliance = jurisdiction['compliance'] as int;
    final complianceColor = _getComplianceColor(compliance);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
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
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CustomIconWidget(
                  iconName: 'flag',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jurisdiction['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      jurisdiction['code'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$compliance%',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: complianceColor,
                    ),
                  ),
                  Text(
                    'Compliant',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: compliance / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: complianceColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Requirements',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: (jurisdiction['requirements'] as List).map<Widget>((req) {
              return Chip(
                label: Text(
                  req as String,
                  style: GoogleFonts.inter(fontSize: 10.sp),
                ),
                backgroundColor: theme.colorScheme.primary.withAlpha(26),
                labelStyle: GoogleFonts.inter(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.orange.withAlpha(51)),
            ),
            child: Row(
              children: [
                Icon(Icons.event, size: 16, color: Colors.orange),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Next Deadline: ${jurisdiction['nextDeadline']}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getComplianceColor(int compliance) {
    if (compliance >= 90) return Colors.green;
    if (compliance >= 75) return Colors.orange;
    return Colors.red;
  }
}
