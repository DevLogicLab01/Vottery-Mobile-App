import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class PerplexityForecastPanelWidget extends StatelessWidget {
  final int horizonDays;
  final List<Map<String, dynamic>> forecasts;
  final List<Map<String, dynamic>> mitigationRecommendations;
  final bool isLoading;

  const PerplexityForecastPanelWidget({
    super.key,
    required this.horizonDays,
    required this.forecasts,
    required this.mitigationRecommendations,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final categories = [
      'fraud',
      'payment_anomaly',
      'security_breach',
      'account_takeover',
    ];
    final categoryColors = [
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.blue,
    ];
    final categoryLabels = [
      'Fraud',
      'Payment Anomaly',
      'Security Breach',
      'Account Takeover',
    ];
    final Map<String, int> categoryCounts = {};
    for (final cat in categories) {
      categoryCounts[cat] = forecasts
          .where((f) => f['threat_category'] == cat)
          .length;
    }
    final maxY = categoryCounts.values.isEmpty
        ? 10.0
        : (categoryCounts.values.reduce((a, b) => a > b ? a : b) + 2)
              .toDouble();

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$horizonDays-Day Threat Forecast',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Powered by Perplexity Extended Reasoning',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[500]),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 22.h,
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = [
                          'Fraud',
                          'Payment',
                          'Security',
                          'Account',
                        ];
                        if (value.toInt() < labels.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 0.5.h),
                            child: Text(
                              labels[value.toInt()],
                              style: GoogleFonts.inter(
                                fontSize: 8.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(categories.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (categoryCounts[categories[i]] ?? 0).toDouble(),
                        color: categoryColors[i],
                        width: 4.w,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Confidence Intervals',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          ...List.generate(categories.length, (i) {
            final count = categoryCounts[categories[i]] ?? 0;
            final upper = (count * 1.3).round();
            final lower = (count * 0.7).round();
            return Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: categoryColors[i].withAlpha(13),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: categoryColors[i].withAlpha(51)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3.w,
                    height: 3.w,
                    decoration: BoxDecoration(
                      color: categoryColors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      categoryLabels[i],
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Text(
                    '$lower - $upper',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: categoryColors[i],
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 2.h),
          Text(
            'Mitigation Recommendations',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          if (mitigationRecommendations.isEmpty)
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'No mitigation recommendations available',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey[500],
                ),
              ),
            )
          else
            ...mitigationRecommendations
                .take(3)
                .map((rec) => _ActionableInsightCard(recommendation: rec)),
        ],
      ),
    );
  }
}

class _ActionableInsightCard extends StatelessWidget {
  final Map<String, dynamic> recommendation;
  const _ActionableInsightCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final impact = recommendation['impact_score'] as double? ?? 0.0;
    final impactColor = impact > 0.7
        ? Colors.red
        : impact > 0.4
        ? Colors.orange
        : Colors.green;
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recommendation['title'] as String? ?? 'Recommendation',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: impactColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  'Impact: ${(impact * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: impactColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          Text(
            recommendation['description'] as String? ?? '',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (recommendation['estimated_cost'] != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              'Est. Cost: ${recommendation['estimated_cost']}',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
