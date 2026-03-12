import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

/// AI Feature Usage Panel - Bar chart showing top features
class AIFeatureUsagePanelWidget extends StatelessWidget {
  final Map<String, int> featureUsage;

  const AIFeatureUsagePanelWidget({super.key, required this.featureUsage});

  static const Map<String, String> _featureLabels = {
    'ai_consensus_used': 'Consensus Analysis',
    'quest_completed': 'Quest Completion',
    'ai_content_moderation': 'Content Moderation',
    'ai_quest_generation': 'Quest Generation',
    'vp_earned': 'VP Earned',
  };

  static const Map<String, Color> _featureColors = {
    'ai_consensus_used': Colors.blue,
    'quest_completed': Colors.green,
    'ai_content_moderation': Colors.orange,
    'ai_quest_generation': Colors.purple,
    'vp_earned': Colors.amber,
  };

  @override
  Widget build(BuildContext context) {
    final sortedEntries = featureUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sortedEntries.isEmpty ? 1 : sortedEntries.first.value;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Feature Usage',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Top features by interaction count with trend indicators',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue.toDouble() * 1.2,
                barGroups: sortedEntries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  final color = _featureColors[e.key] ?? Colors.blue;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.toDouble(),
                        color: color,
                        width: 4.w,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 10.w,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= sortedEntries.length) {
                          return const SizedBox();
                        }
                        final key = sortedEntries[idx].key;
                        final label = _featureLabels[key] ?? key;
                        return Padding(
                          padding: EdgeInsets.only(top: 0.5.h),
                          child: Text(
                            label.split(' ').first,
                            style: GoogleFonts.inter(
                              fontSize: 7.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
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
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.withAlpha(40), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Feature Details',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          ...sortedEntries.map(
            (e) => _buildFeatureRow(e.key, e.value, maxValue),
          ),
          SizedBox(height: 2.h),
          _buildCustomDimensionsCard(),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String key, int count, int maxValue) {
    final label = _featureLabels[key] ?? key;
    final color = _featureColors[key] ?? Colors.blue;
    final pct = maxValue > 0 ? count / maxValue : 0.0;
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 3.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.3.h),
                LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.grey.withAlpha(40),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            count.toString(),
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(width: 1.w),
          Icon(Icons.trending_up, color: Colors.green, size: 3.5.w),
        ],
      ),
    );
  }

  Widget _buildCustomDimensionsCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.indigo.withAlpha(20),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.indigo.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GA4 Custom Dimensions',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: Colors.indigo,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 0.5.h,
            children: [
              _buildDimensionChip('consensus_type'),
              _buildDimensionChip('quest_difficulty'),
              _buildDimensionChip('earning_source'),
              _buildDimensionChip('moderation_action'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionChip(String label) {
    return Chip(
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.indigo),
      ),
      backgroundColor: Colors.indigo.withAlpha(30),
      side: BorderSide(color: Colors.indigo.withAlpha(80)),
      padding: EdgeInsets.symmetric(horizontal: 1.w),
    );
  }
}
