import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PredictiveModelingDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const PredictiveModelingDashboardWidget({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.indigo.shade700,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Predictive Modeling Dashboard',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '24-48 Hour Fraud Forecasting',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildForecastCard(
              '24-Hour Forecast',
              'Medium Risk',
              0.72,
              'Expected 12-15 fraud attempts',
              Colors.orange,
            ),
            SizedBox(height: 1.h),
            _buildForecastCard(
              '48-Hour Forecast',
              'High Risk',
              0.85,
              'Expected 25-30 fraud attempts',
              Colors.red,
            ),
            SizedBox(height: 2.h),
            Text(
              'Prevention Recommendations',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            _buildRecommendation(
              'Increase monitoring on high-risk accounts',
              Icons.visibility,
            ),
            _buildRecommendation(
              'Enable stricter verification for new users',
              Icons.verified_user,
            ),
            _buildRecommendation(
              'Review payment processing thresholds',
              Icons.payment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(
    String title,
    String riskLevel,
    double confidence,
    String description,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  riskLevel,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade700),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(
                'Confidence:',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: LinearProgressIndicator(
                  value: confidence,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo.shade700, size: 16.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
