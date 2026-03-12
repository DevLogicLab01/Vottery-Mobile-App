import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Forecast Header Widget
/// Displays prediction confidence, model accuracy, and last update timestamp
class ForecastHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> forecast;

  const ForecastHeaderWidget({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = forecast['confidence_percentage'] ?? 0.0;
    final forecastDate = forecast['forecast_date'] != null
        ? DateTime.parse(forecast['forecast_date'])
        : DateTime.now();
    final timeAgo = _getTimeAgo(forecastDate);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha(179),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'AI Forecast',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'GPT-5',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric(
                'Confidence',
                '${confidence.toStringAsFixed(1)}%',
                Icons.trending_up,
              ),
              _buildMetric(
                'Horizon',
                '${forecast['forecast_horizon_days'] ?? 30} days',
                Icons.calendar_today,
              ),
              _buildMetric('Updated', timeAgo, Icons.access_time),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 4.w),
            SizedBox(width: 1.w),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: Colors.white70),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
