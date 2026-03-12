import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class PredictiveRevenuePanelWidget extends StatelessWidget {
  final Map<String, dynamic> forecastData;
  final List<FlSpot> historicalSpots;
  final List<FlSpot> predictedSpots;

  const PredictiveRevenuePanelWidget({
    super.key,
    required this.forecastData,
    required this.historicalSpots,
    required this.predictedSpots,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF313244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: Color(0xFFCBA6F7), size: 18),
              SizedBox(width: 2.w),
              Text(
                'Predictive Revenue Modeling',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            'OpenAI-powered 30/60/90-day forecasts',
            style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white38),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildForecastCard(
                  '30-Day',
                  forecastData['forecast_30d'] as double? ?? 0,
                  forecastData['confidence_30d'] as double? ?? 0.85,
                  const Color(0xFF89B4FA),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildForecastCard(
                  '60-Day',
                  forecastData['forecast_60d'] as double? ?? 0,
                  forecastData['confidence_60d'] as double? ?? 0.75,
                  const Color(0xFFA6E3A1),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildForecastCard(
                  '90-Day',
                  forecastData['forecast_90d'] as double? ?? 0,
                  forecastData['confidence_90d'] as double? ?? 0.65,
                  const Color(0xFFF9E2AF),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 18.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: const Color(0xFF313244), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final labels = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                        ];
                        final idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Text(
                            labels[idx],
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              color: Colors.white38,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value / 1000).toStringAsFixed(0)}K',
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            color: Colors.white38,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: historicalSpots,
                    isCurved: true,
                    color: const Color(0xFF89B4FA),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF89B4FA).withAlpha(26),
                    ),
                  ),
                  LineChartBarData(
                    spots: predictedSpots,
                    isCurved: true,
                    color: const Color(0xFFF9E2AF),
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFF9E2AF).withAlpha(13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(const Color(0xFF89B4FA), 'Historical'),
              SizedBox(width: 4.w),
              _buildLegendDot(const Color(0xFFF9E2AF), 'Predicted'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(
    String period,
    double amount,
    double confidence,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(64)),
      ),
      child: Column(
        children: [
          Text(
            period,
            style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white54),
          ),
          SizedBox(height: 0.3.h),
          Text(
            '\$${(amount / 1000).toStringAsFixed(1)}K',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            '${(confidence * 100).toStringAsFixed(0)}% conf.',
            style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 3, color: color),
        SizedBox(width: 1.w),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white54),
        ),
      ],
    );
  }
}
