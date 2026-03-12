import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart'
    as google_fonts; // Add alias to avoid conflicts

class SeasonalAnomalyChartsWidget extends StatelessWidget {
  const SeasonalAnomalyChartsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seasonal Fraud Patterns',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildSeasonalChart(context),
          SizedBox(height: 3.h),
          Text(
            'Anomaly Detection',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildAnomalyCards(context),
        ],
      ),
    );
  }

  Widget _buildSeasonalChart(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec',
                  ];
                  if (value.toInt() >= 0 && value.toInt() < months.length) {
                    return Text(
                      months[value.toInt()],
                      style: google_fonts.GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: theme.dividerColor, strokeWidth: 1);
            },
          ),
          barGroups: [
            _makeBarGroup(0, 45, Colors.blue),
            _makeBarGroup(1, 52, Colors.blue),
            _makeBarGroup(2, 48, Colors.blue),
            _makeBarGroup(3, 65, Colors.orange),
            _makeBarGroup(4, 58, Colors.blue),
            _makeBarGroup(5, 72, Colors.orange),
            _makeBarGroup(6, 68, Colors.blue),
            _makeBarGroup(7, 55, Colors.blue),
            _makeBarGroup(8, 62, Colors.blue),
            _makeBarGroup(9, 78, Colors.red),
            _makeBarGroup(10, 85, Colors.red),
            _makeBarGroup(11, 92, Colors.red),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4.0),
        ),
      ],
    );
  }

  Widget _buildAnomalyCards(BuildContext context) {
    final theme = Theme.of(context);

    final anomalies = [
      {
        'period': 'Q4 2025 (Oct-Dec)',
        'deviation': '+45%',
        'description': 'Holiday season spike in account takeover attempts',
        'severity': 'high',
      },
      {
        'period': 'Q2 2025 (Apr-Jun)',
        'deviation': '+28%',
        'description': 'Tax season related identity theft increase',
        'severity': 'medium',
      },
      {
        'period': 'Q1 2025 (Jan-Mar)',
        'deviation': '+12%',
        'description': 'Post-holiday return fraud patterns',
        'severity': 'low',
      },
    ];

    return Column(
      children: anomalies.map((anomaly) {
        final severityColor = _getSeverityColor(anomaly['severity'] as String);

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: severityColor.withAlpha(51)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            anomaly['period'] as String,
                            style: google_fonts.GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          anomaly['deviation'] as String,
                          style: google_fonts.GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: severityColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      anomaly['description'] as String,
                      style: google_fonts.GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }
}
