import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Compliance Status Header Widget
/// Displays overall compliance score and key metrics
class ComplianceStatusHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> complianceStatus;

  const ComplianceStatusHeaderWidget({
    super.key,
    required this.complianceStatus,
  });

  @override
  Widget build(BuildContext context) {
    final score = complianceStatus['compliance_score'] ?? 0;
    final validDocs = complianceStatus['valid_documents'] ?? 0;
    final expiringSoon = complianceStatus['expiring_soon'] ?? 0;
    final jurisdictions = complianceStatus['jurisdictions_registered'] ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.primaryLight.withAlpha(179)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compliance Score',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: _getScoreColor(score),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Valid Documents',
                validDocs.toString(),
                Icons.check_circle,
              ),
              _buildStatItem(
                'Expiring Soon',
                expiringSoon.toString(),
                Icons.warning,
              ),
              _buildStatItem(
                'Jurisdictions',
                jurisdictions.toString(),
                Icons.public,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 6.w),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.white.withAlpha(204)),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
