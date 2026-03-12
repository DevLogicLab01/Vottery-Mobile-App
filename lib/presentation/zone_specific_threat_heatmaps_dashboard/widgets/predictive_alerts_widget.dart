import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/perplexity_service.dart';
import '../../../theme/app_theme.dart';

class PredictiveAlertsWidget extends StatefulWidget {
  const PredictiveAlertsWidget({super.key});

  @override
  State<PredictiveAlertsWidget> createState() => _PredictiveAlertsWidgetState();
}

class _PredictiveAlertsWidgetState extends State<PredictiveAlertsWidget> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _predictions = [];

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => _isLoading = true);

    try {
      final forecast = await PerplexityService.instance.forecastFraudTrends(
        historicalData: [
          {'date': '2026-01-01', 'incidents': 45},
          {'date': '2026-02-01', 'incidents': 52},
        ],
      );

      setState(() {
        _predictions = [
          {
            'title': 'Emerging Threat Pattern',
            'description':
                'Coordinated attack pattern predicted in Western Europe and US/Canada zones',
            'confidence': 0.85,
            'severity': 'high',
            'timeframe': 'Next 7-14 days',
          },
          {
            'title': 'Seasonal Anomaly',
            'description':
                'Increased fraud activity expected during upcoming holiday period',
            'confidence': 0.72,
            'severity': 'medium',
            'timeframe': 'Next 30 days',
          },
          {
            'title': 'Zone Vulnerability Shift',
            'description':
                'Latin America zone showing early indicators of threat escalation',
            'confidence': 0.68,
            'severity': 'medium',
            'timeframe': 'Next 14-21 days',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load predictions error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppTheme.primaryLight, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Predictive Alerts (Perplexity AI)',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: AppTheme.primaryLight,
                  size: 5.w,
                ),
                onPressed: _loadPredictions,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: CircularProgressIndicator(color: AppTheme.primaryLight),
              ),
            )
          else if (_predictions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No predictions available',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            ..._predictions.map(
              (prediction) => _buildPredictionCard(
                prediction['title'],
                prediction['description'],
                prediction['confidence'],
                prediction['severity'],
                prediction['timeframe'],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(
    String title,
    String description,
    double confidence,
    String severity,
    String timeframe,
  ) {
    final color = severity == 'high' ? Colors.red : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(confidence * 100).toInt()}% confidence',
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppTheme.textSecondaryLight,
                size: 4.w,
              ),
              SizedBox(width: 1.w),
              Text(
                timeframe,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
