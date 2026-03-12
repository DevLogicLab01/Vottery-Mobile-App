import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EmergingThreatIdentificationWidget extends StatelessWidget {
  const EmergingThreatIdentificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final threats = [
      {
        'type': 'AI-Generated Deepfake Attacks',
        'severity': 'critical',
        'likelihood': 0.78,
        'impact': 0.92,
        'description':
            'Sophisticated deepfake technology used for identity fraud',
        'firstDetected': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'type': 'Synthetic Identity Fraud',
        'severity': 'high',
        'likelihood': 0.65,
        'impact': 0.85,
        'description':
            'Combination of real and fake information to create new identities',
        'firstDetected': DateTime.now().subtract(const Duration(days: 5)),
      },
      {
        'type': 'Account Takeover via Social Engineering',
        'severity': 'high',
        'likelihood': 0.72,
        'impact': 0.78,
        'description': 'Targeted phishing campaigns exploiting user trust',
        'firstDetected': DateTime.now().subtract(const Duration(days: 7)),
      },
      {
        'type': 'Automated Bot Networks',
        'severity': 'medium',
        'likelihood': 0.58,
        'impact': 0.65,
        'description': 'Coordinated bot attacks on voting systems',
        'firstDetected': DateTime.now().subtract(const Duration(days: 10)),
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: threats.length,
      itemBuilder: (context, index) {
        return _buildThreatCard(context, threats[index]);
      },
    );
  }

  Widget _buildThreatCard(BuildContext context, Map<String, dynamic> threat) {
    final theme = Theme.of(context);
    final severity = threat['severity'] as String;
    final severityColor = _getSeverityColor(severity);
    final likelihood = threat['likelihood'] as double;
    final impact = threat['impact'] as double;
    final riskScore = (likelihood * impact * 100).toInt();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: severityColor.withAlpha(51)),
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
                  color: severityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CustomIconWidget(
                  iconName: 'warning',
                  color: severityColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  threat['type'] as String,
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
                  color: severityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            threat['description'] as String,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricBar(
                  context,
                  'Likelihood',
                  likelihood,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricBar(context, 'Impact', impact, Colors.red),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: _getRiskColor(riskScore).withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Risk Score',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '$riskScore/100',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _getRiskColor(riskScore),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 1.w),
              Text(
                'First detected: ${_formatDate(threat['firstDetected'] as DateTime)}',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBar(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: theme.dividerColor,
            borderRadius: BorderRadius.circular(3.0),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3.0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade900;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskColor(int score) {
    if (score >= 75) return Colors.red;
    if (score >= 50) return Colors.orange;
    return Colors.yellow.shade700;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
