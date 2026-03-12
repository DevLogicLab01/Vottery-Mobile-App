import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class WaterfallVerificationWorkflowWidget extends StatelessWidget {
  const WaterfallVerificationWorkflowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'Waterfall Verification Approach',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        _buildWorkflowStep(
          1,
          'Facial Age Estimation',
          'AI-powered facial biometrics (Yoti SDK)',
          'If borderline (15-21 years), proceed to Step 2',
          Colors.blue,
        ),
        SizedBox(height: 2.h),
        _buildWorkflowStep(
          2,
          'Government ID Verification',
          'Document upload + biometric matching',
          'If document unavailable, proceed to Step 3',
          Colors.orange,
        ),
        SizedBox(height: 2.h),
        _buildWorkflowStep(
          3,
          'Digital Identity Wallet',
          'Yoti Keys/AgeKey reusable verification',
          'Privacy-preserving authentication',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildWorkflowStep(
    int stepNumber,
    String title,
    String description,
    String fallback,
    Color color,
  ) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      fallback,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
