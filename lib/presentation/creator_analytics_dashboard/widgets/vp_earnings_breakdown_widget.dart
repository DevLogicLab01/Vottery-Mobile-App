import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class VPEarningsBreakdownWidget extends StatelessWidget {
  final Map<String, dynamic> vpData;

  const VPEarningsBreakdownWidget({super.key, required this.vpData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
            'VP Earnings Breakdown',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildTimePeriodSelector(theme),
          SizedBox(height: 2.h),
          _buildVPSourcesGrid(theme),
          SizedBox(height: 2.h),
          _buildEarningsChart(theme),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector(ThemeData theme) {
    return Row(
      children: [
        _buildPeriodChip('Daily', true, theme),
        SizedBox(width: 2.w),
        _buildPeriodChip('Weekly', false, theme),
        SizedBox(width: 2.w),
        _buildPeriodChip('Monthly', false, theme),
      ],
    );
  }

  Widget _buildPeriodChip(String label, bool isSelected, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary : Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildVPSourcesGrid(ThemeData theme) {
    final sources = [
      {
        'name': 'Elections',
        'vp': vpData['elections_vp'] ?? 0,
        'rate': '10 VP/vote',
        'icon': Icons.how_to_vote,
      },
      {
        'name': 'Ads',
        'vp': vpData['ads_vp'] ?? 0,
        'rate': '5 VP/interaction',
        'icon': Icons.ads_click,
      },
      {
        'name': 'Jolts',
        'vp': vpData['jolts_vp'] ?? 0,
        'rate': '50 VP/creation',
        'icon': Icons.video_library,
      },
      {
        'name': 'Predictions',
        'vp': vpData['predictions_vp'] ?? 0,
        'rate': 'Up to 1000 VP',
        'icon': Icons.psychology,
      },
      {
        'name': 'Social',
        'vp': vpData['social_vp'] ?? 0,
        'rate': '5 VP/like',
        'icon': Icons.favorite,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 1.5,
      ),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        return Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withAlpha(26),
                theme.colorScheme.secondary.withAlpha(26),
              ],
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    source['icon'] as IconData,
                    size: 20.sp,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      source['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                '${source['vp']} VP',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                source['rate'] as String,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningsChart(ThemeData theme) {
    final chartData = vpData['daily_earnings'] as List<dynamic>? ?? [];

    return SizedBox(
      height: 25.h,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40.0,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                    return Text(
                      chartData[value.toInt()]['day'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                chartData.length,
                (index) => FlSpot(
                  index.toDouble(),
                  (chartData[index]['vp'] ?? 0).toDouble(),
                ),
              ),
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3.0,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withAlpha(51),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
