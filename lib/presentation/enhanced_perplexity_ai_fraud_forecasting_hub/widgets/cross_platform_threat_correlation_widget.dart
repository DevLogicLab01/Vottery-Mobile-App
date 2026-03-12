import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CrossPlatformThreatCorrelationWidget extends StatelessWidget {
  const CrossPlatformThreatCorrelationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final correlations = [
      {
        'platforms': ['Voting System', 'Payment Gateway'],
        'threatType': 'Credential Stuffing',
        'correlation': 0.87,
        'affectedUsers': 1245,
        'riskScore': 85,
      },
      {
        'platforms': ['Social Feed', 'Direct Messaging'],
        'threatType': 'Phishing Campaign',
        'correlation': 0.72,
        'affectedUsers': 892,
        'riskScore': 72,
      },
      {
        'platforms': ['Election Creation', 'VP Economy'],
        'threatType': 'Bot Network Activity',
        'correlation': 0.65,
        'affectedUsers': 567,
        'riskScore': 68,
      },
      {
        'platforms': ['User Profiles', 'Gamification'],
        'threatType': 'Account Takeover',
        'correlation': 0.58,
        'affectedUsers': 423,
        'riskScore': 55,
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: correlations.length,
      itemBuilder: (context, index) {
        return _buildCorrelationCard(context, correlations[index]);
      },
    );
  }

  Widget _buildCorrelationCard(
    BuildContext context,
    Map<String, dynamic> correlation,
  ) {
    final theme = Theme.of(context);
    final correlationValue = correlation['correlation'] as double;
    final riskScore = correlation['riskScore'] as int;
    final riskColor = _getRiskColor(riskScore);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: riskColor.withAlpha(51)),
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
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CustomIconWidget(
                  iconName: 'link',
                  color: riskColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  correlation['threatType'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'Risk: $riskScore',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Affected Platforms',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: (correlation['platforms'] as List<String>).map((
              platform,
            ) {
              return Chip(
                label: Text(
                  platform,
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correlation Strength',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: correlationValue,
                        child: Container(
                          decoration: BoxDecoration(
                            color: riskColor,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${(correlationValue * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Affected Users',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    correlation['affectedUsers'].toString(),
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () =>
                _investigateThreat(context, correlation['threatType']),
            icon: Icon(Icons.search, size: 16),
            label: Text('Investigate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(int score) {
    if (score >= 75) return Colors.red;
    if (score >= 50) return Colors.orange;
    return Colors.yellow.shade700;
  }

  void _investigateThreat(BuildContext context, String threatType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening detailed investigation for $threatType'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
