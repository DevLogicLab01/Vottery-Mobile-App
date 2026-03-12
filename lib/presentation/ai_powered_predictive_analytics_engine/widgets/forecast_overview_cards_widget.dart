import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ForecastOverviewCardsWidget extends StatelessWidget {
  final Map<String, dynamic> trafficForecast;
  final Map<String, dynamic> fraudForecast;
  final Map<String, dynamic> infrastructureForecast;
  final Function(String) onViewDetails;

  const ForecastOverviewCardsWidget({
    super.key,
    required this.trafficForecast,
    required this.fraudForecast,
    required this.infrastructureForecast,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTrafficCard(),
        SizedBox(height: 2.h),
        _buildFraudCard(),
        SizedBox(height: 2.h),
        _buildInfrastructureCard(),
      ],
    );
  }

  Widget _buildTrafficCard() {
    final forecast30d = trafficForecast['forecast_30d'] as List? ?? [];
    final avgTraffic = forecast30d.isNotEmpty
        ? forecast30d
                  .map((d) => d['expected_daily_traffic'] as num? ?? 0)
                  .reduce((a, b) => a + b) /
              forecast30d.length
        : 0;
    final confidence = trafficForecast['confidence_score'] as double? ?? 0.5;

    return _buildCard(
      title: '30-Day Traffic Forecast',
      icon: Icons.trending_up,
      iconColor: Colors.blue,
      metrics: [
        {
          'label': 'Predicted Daily Avg',
          'value': avgTraffic.toStringAsFixed(0),
        },
        {
          'label': 'Confidence',
          'value': '${(confidence * 100).toStringAsFixed(0)}%',
        },
      ],
      onTap: () => onViewDetails('traffic'),
    );
  }

  Widget _buildFraudCard() {
    final fraudAttempts =
        fraudForecast['predicted_fraud_attempts_per_day'] as num? ?? 0;
    final financialImpact =
        fraudForecast['predicted_financial_impact'] as num? ?? 0;
    final confidence = fraudForecast['confidence_score'] as double? ?? 0.5;

    return _buildCard(
      title: '60-Day Fraud Trend',
      icon: Icons.security,
      iconColor: Colors.red,
      metrics: [
        {'label': 'Predicted Attempts/Day', 'value': fraudAttempts.toString()},
        {
          'label': 'Est. Impact',
          'value': '\$${financialImpact.toStringAsFixed(0)}',
        },
        {
          'label': 'Confidence',
          'value': '${(confidence * 100).toStringAsFixed(0)}%',
        },
      ],
      onTap: () => onViewDetails('fraud'),
    );
  }

  Widget _buildInfrastructureCard() {
    final recommendations =
        infrastructureForecast['scaling_recommendations'] as List? ?? [];
    final nextAction = recommendations.isNotEmpty
        ? recommendations.first
        : null;
    final totalCost =
        infrastructureForecast['total_estimated_cost'] as num? ?? 0;

    return _buildCard(
      title: '90-Day Infrastructure Needs',
      icon: Icons.storage,
      iconColor: Colors.green,
      metrics: [
        {
          'label': 'Next Action',
          'value': nextAction != null
              ? '${nextAction['resource_type']} scaling'
              : 'None',
        },
        {'label': 'Est. Cost', 'value': '\$${totalCost.toStringAsFixed(0)}'},
      ],
      onTap: () => onViewDetails('infrastructure'),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, String>> metrics,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10.0,
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
                    color: iconColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(icon, color: iconColor, size: 24.sp),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
              ],
            ),
            SizedBox(height: 2.h),
            ...metrics.map(
              (metric) => Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      metric['label']!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      metric['value']!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
