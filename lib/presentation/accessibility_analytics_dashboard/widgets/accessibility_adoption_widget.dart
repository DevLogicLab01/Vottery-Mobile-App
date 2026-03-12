import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AccessibilityAdoptionWidget extends StatelessWidget {
  final Map<String, dynamic> adoptionData;

  const AccessibilityAdoptionWidget({super.key, required this.adoptionData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accessibility Feature Adoption',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Adoption rates by user segment with feature usage heatmaps',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          _buildAdoptionCard(
            'Screen Reader Usage',
            'Accessibility API integration',
            8.5,
            Icons.record_voice_over,
            Colors.blue,
          ),
          SizedBox(height: 2.h),
          _buildAdoptionCard(
            'High Contrast Mode',
            'Enhanced visibility settings',
            12.3,
            Icons.contrast,
            Colors.purple,
          ),
          SizedBox(height: 2.h),
          _buildAdoptionCard(
            'Reduced Motion',
            'Animation preferences',
            6.7,
            Icons.motion_photos_off,
            Colors.orange,
          ),
          SizedBox(height: 3.h),
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildAdoptionCard(
    String feature,
    String description,
    double adoptionRate,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        description,
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${adoptionRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: adoptionRate / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 1.h,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, size: 20.sp, color: Colors.amber),
                SizedBox(width: 2.w),
                Text(
                  'Personalized Recommendations',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildRecommendationItem(
              'Promote high contrast mode to users with low engagement',
              Colors.purple,
            ),
            SizedBox(height: 1.h),
            _buildRecommendationItem(
              'Suggest reduced motion for users with frequent app crashes',
              Colors.orange,
            ),
            SizedBox(height: 1.h),
            _buildRecommendationItem(
              'Enable automatic font scaling for users over 55',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.arrow_right, size: 20.sp, color: color),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
