import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SystemComplianceCardWidget extends StatelessWidget {
  final String systemName;
  final int complianceScore;
  final int violationCount;
  final String riskLevel;
  final VoidCallback onTap;

  const SystemComplianceCardWidget({
    super.key,
    required this.systemName,
    required this.complianceScore,
    required this.violationCount,
    required this.riskLevel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    if (complianceScore >= 90) {
      scoreColor = Colors.green;
    } else if (complianceScore >= 70) {
      scoreColor = Colors.orange;
    } else if (complianceScore >= 50) {
      scoreColor = Colors.yellow[700]!;
    } else {
      scoreColor = Colors.red;
    }

    IconData riskIcon;
    Color riskColor;
    switch (riskLevel) {
      case 'critical':
        riskIcon = Icons.error;
        riskColor = Colors.red;
        break;
      case 'high':
        riskIcon = Icons.warning;
        riskColor = Colors.orange;
        break;
      case 'medium':
        riskIcon = Icons.info;
        riskColor = Colors.yellow[700]!;
        break;
      default:
        riskIcon = Icons.check_circle;
        riskColor = Colors.green;
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: scoreColor, width: 2.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      systemName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(riskIcon, color: riskColor, size: 20),
                ],
              ),
              SizedBox(height: 1.h),
              Center(
                child: Text(
                  '$complianceScore',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Compliance Score',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ),
              SizedBox(height: 1.h),
              if (violationCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 12, color: Colors.red),
                      SizedBox(width: 1.w),
                      Text(
                        '$violationCount violation${violationCount > 1 ? "s" : ""}',
                        style: TextStyle(fontSize: 10.sp, color: Colors.red),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
