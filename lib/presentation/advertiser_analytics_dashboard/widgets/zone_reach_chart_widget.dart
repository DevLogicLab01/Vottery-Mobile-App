import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ZoneReachChartWidget extends StatelessWidget {
  final Map<String, int> zoneReach;
  final Map<String, int> zoneConversions;

  const ZoneReachChartWidget({
    super.key,
    required this.zoneReach,
    required this.zoneConversions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.0),
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
          Text(
            'Reach by Zone',
            style: GoogleFonts.inter(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.0),
          SizedBox(
            height: 30.0,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxValue() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final zoneName = _getZoneName(groupIndex);
                      final value = rod.toY.toInt();
                      return BarTooltipItem(
                        '$zoneName\n$value',
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.0,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: EdgeInsets.only(top: 1.0),
                          child: Text(
                            'Z${value.toInt() + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 9.0,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 10.0,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatNumber(value.toInt()),
                          style: GoogleFonts.inter(
                            fontSize: 9.0,
                            color: AppTheme.textSecondaryLight,
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxValue() / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.borderLight,
                      strokeWidth: 1.0,
                    );
                  },
                ),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
          SizedBox(height: 2.0),
          _buildLegend(),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final zones = [
      'zone_1_us_canada',
      'zone_2_western_europe',
      'zone_3_eastern_europe_russia',
      'zone_4_africa',
      'zone_5_latin_america_caribbean',
      'zone_6_middle_east_asia',
      'zone_7_australasia_advanced_asia',
      'zone_8_china_hong_kong_macau',
    ];

    return List.generate(zones.length, (index) {
      final zone = zones[index];
      final reach = (zoneReach[zone] ?? 0).toDouble();
      final conversions = (zoneConversions[zone] ?? 0).toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: reach,
            color: AppTheme.primaryLight,
            width: 3.0,
            borderRadius: BorderRadius.circular(4.0),
          ),
          BarChartRodData(
            toY: conversions,
            color: Colors.green,
            width: 3.0,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ],
      );
    });
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Reach', AppTheme.primaryLight),
        SizedBox(width: 4.0),
        _buildLegendItem('Conversions', Colors.green),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 3.0,
          height: 3.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        SizedBox(width: 1.0),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.0,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  double _getMaxValue() {
    final allValues = [...zoneReach.values, ...zoneConversions.values];
    return allValues.isEmpty
        ? 100
        : allValues.reduce((a, b) => a > b ? a : b).toDouble();
  }

  String _getZoneName(int index) {
    const names = [
      'US & Canada',
      'Western Europe',
      'Eastern Europe',
      'Africa',
      'Latin America',
      'Middle East & Asia',
      'Australasia',
      'China & Hong Kong',
    ];
    return names[index];
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}
