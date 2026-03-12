import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class EarningSpendingBalanceChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> dailyData;

  const EarningSpendingBalanceChartWidget({super.key, required this.dailyData});

  @override
  Widget build(BuildContext context) {
    final earningSpots = _buildSpots('earned');
    final spendingSpots = _buildSpots('spent');
    final balanceSpots = _buildBalanceSpots(earningSpots, spendingSpots);

    final allValues = [
      ...earningSpots.map((s) => s.y),
      ...spendingSpots.map((s) => s.y),
      ...balanceSpots.map((s) => s.y),
    ];
    final maxY = allValues.isEmpty
        ? 1000.0
        : allValues.reduce((a, b) => a > b ? a : b) * 1.2;
    final minY = allValues.isEmpty
        ? -500.0
        : allValues.reduce((a, b) => a < b ? a : b) * 1.2;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earning vs Spending Balance',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildLegend('Earned', const Color(0xFF4CAF50)),
              SizedBox(width: 3.w),
              _buildLegend('Spent', const Color(0xFFFF6B6B)),
              SizedBox(width: 3.w),
              _buildLegend('Balance', const Color(0xFF6C63FF)),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 20.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.withAlpha(38), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 5,
                      getTitlesWidget: (v, m) => Text(
                        'D${v.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, m) => Text(
                        _formatK(v),
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          color: Colors.grey[500],
                        ),
                      ),
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
                minX: 1,
                maxX: 30,
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  _buildLine(earningSpots, const Color(0xFF4CAF50)),
                  _buildLine(spendingSpots, const Color(0xFFFF6B6B)),
                  _buildLine(
                    balanceSpots,
                    const Color(0xFF6C63FF),
                    isDashed: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(
    List<FlSpot> spots,
    Color color, {
    bool isDashed = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: isDashed ? 1.5 : 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      dashArray: isDashed ? [5, 3] : null,
      belowBarData: BarAreaData(show: false),
    );
  }

  List<FlSpot> _buildSpots(String key) {
    if (dailyData.isEmpty) {
      return List.generate(30, (i) {
        final base = key == 'earned' ? 800.0 + (i * 12) : 600.0 + (i * 8);
        return FlSpot((i + 1).toDouble(), base + (i % 5 == 0 ? 100 : 0));
      });
    }
    return dailyData.asMap().entries.map((e) {
      return FlSpot(
        (e.key + 1).toDouble(),
        (e.value[key] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  List<FlSpot> _buildBalanceSpots(List<FlSpot> earned, List<FlSpot> spent) {
    double cumulative = 0;
    return List.generate(earned.length, (i) {
      cumulative += (earned[i].y - (i < spent.length ? spent[i].y : 0));
      return FlSpot(earned[i].x, cumulative);
    });
  }

  String _formatK(double v) {
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toInt().toString();
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 3, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
