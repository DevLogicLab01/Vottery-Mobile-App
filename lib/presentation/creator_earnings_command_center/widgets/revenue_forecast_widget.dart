import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RevenueForecastWidget extends StatelessWidget {
  final Map<String, dynamic> forecast;
  final double currentEarnings;

  const RevenueForecastWidget({
    super.key,
    required this.forecast,
    required this.currentEarnings,
  });

  @override
  Widget build(BuildContext context) {
    final forecast30 = forecast['30_day_forecast'] ?? 0.0;
    final forecast60 = forecast['60_day_forecast'] ?? 0.0;
    final forecast90 = forecast['90_day_forecast'] ?? 0.0;
    final confidence = forecast['confidence_score'] ?? 0.0;
    final trend = forecast['trend'] ?? 'stable';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Forecast',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getTrendColor(trend).withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTrendIcon(trend),
                      color: _getTrendColor(trend),
                      size: 14.sp,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      trend.toUpperCase(),
                      style: TextStyle(
                        color: _getTrendColor(trend),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildForecastCard('30 Days', forecast30, Colors.blue),
          SizedBox(height: 1.h),
          _buildForecastCard('60 Days', forecast60, Colors.purple),
          SizedBox(height: 1.h),
          _buildForecastCard('90 Days', forecast90, Colors.orange),
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.grey, size: 16.sp),
              SizedBox(width: 2.w),
              Text(
                'Confidence Score: ${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(String period, double amount, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            period,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'growing':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'growing':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }
}
