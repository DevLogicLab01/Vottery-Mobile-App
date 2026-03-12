import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ComplianceDashboardWidget extends StatelessWidget {
  const ComplianceDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'ISO/IEC 27566-1:2025 Compliance',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Card(
          elevation: 2.0,
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Compliance Status',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        'Compliant',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildComplianceItem(
                  'Data Minimization',
                  'Binary over-18 signal only',
                  true,
                ),
                _buildComplianceItem(
                  'Selfie Deletion',
                  'Immediate after verification',
                  true,
                ),
                _buildComplianceItem('DOB Storage', 'Not stored', true),
                _buildComplianceItem('Audit Trail', 'Complete logging', true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceItem(
    String label,
    String description,
    bool compliant,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Icon(
            compliant ? Icons.check_circle : Icons.cancel,
            color: compliant ? Colors.green : Colors.red,
            size: 18.sp,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
