import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class GrowthTrajectoryChartWidget extends StatelessWidget {
  final Map<String, dynamic> growthPrediction;

  const GrowthTrajectoryChartWidget({
    super.key,
    required this.growthPrediction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earnings30d =
        (growthPrediction['earnings_30d'] as num?)?.toDouble() ?? 300.0;
    final earnings90d =
        (growthPrediction['earnings_90d'] as num?)?.toDouble() ?? 900.0;
    final upperBound =
        (growthPrediction['confidence_upper'] as num?)?.toDouble() ?? 0.85;
    final lowerBound =
        (growthPrediction['confidence_lower'] as num?)?.toDouble() ?? 0.65;

    // Historical data (mock - last 3 months)
    final historicalSpots = [
      FlSpot(0, earnings90d * 0.4),
      FlSpot(1, earnings90d * 0.55),
      FlSpot(2, earnings90d * 0.7),
      FlSpot(3, earnings30d * 0.9),
    ];

    // Predicted data (next 3 months)
    final predictedSpots = [
      FlSpot(3, earnings30d * 0.9),
      FlSpot(4, earnings30d),
      FlSpot(5, earnings30d * 1.5),
      FlSpot(6, earnings90d),
    ];

    // Upper confidence band
    final upperSpots = predictedSpots
        .map((s) => FlSpot(s.x, s.y * (1 + (1 - upperBound))))
        .toList();

    // Lower confidence band
    final lowerSpots = predictedSpots
        .map((s) => FlSpot(s.x, s.y * lowerBound))
        .toList();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Trajectory',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              _LegendItem(
                color: AppTheme.vibrantYellow,
                label: 'Historical',
                isDashed: false,
              ),
              SizedBox(width: 3.w),
              _LegendItem(
                color: const Color(0xFF10B981),
                label: 'Predicted',
                isDashed: true,
              ),
              SizedBox(width: 3.w),
              _LegendItem(
                color: const Color(0xFF10B981).withAlpha(51),
                label: 'Confidence',
                isDashed: false,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 22.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.outlineVariant.withAlpha(77),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = [
                          'M-3',
                          'M-2',
                          'M-1',
                          'Now',
                          'M+1',
                          'M+2',
                          'M+3',
                        ];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          labels[idx],
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Historical - solid line
                  LineChartBarData(
                    spots: historicalSpots,
                    isCurved: true,
                    color: AppTheme.vibrantYellow,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Predicted - dashed line
                  LineChartBarData(
                    spots: predictedSpots,
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Upper confidence band
                  LineChartBarData(
                    spots: upperSpots,
                    isCurved: true,
                    color: const Color(0xFF10B981).withAlpha(51),
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF10B981).withAlpha(26),
                    ),
                  ),
                  // Lower confidence band
                  LineChartBarData(
                    spots: lowerSpots,
                    isCurved: true,
                    color: const Color(0xFF10B981).withAlpha(51),
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PredictionStat(
                label: '30-Day Forecast',
                value: '\$${earnings30d.toInt()}',
                color: const Color(0xFF10B981),
              ),
              _PredictionStat(
                label: '90-Day Forecast',
                value: '\$${earnings90d.toInt()}',
                color: AppTheme.vibrantYellow,
              ),
              _PredictionStat(
                label: 'Next Tier',
                value: growthPrediction['next_tier_date'] as String? ?? 'TBD',
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDashed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 5.w, height: 2, color: color),
        SizedBox(width: 1.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PredictionStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PredictionStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
