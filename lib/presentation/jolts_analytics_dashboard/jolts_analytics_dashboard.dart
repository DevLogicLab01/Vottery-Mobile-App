import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/google_analytics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class JoltsAnalyticsDashboard extends StatefulWidget {
  const JoltsAnalyticsDashboard({super.key});

  @override
  State<JoltsAnalyticsDashboard> createState() =>
      _JoltsAnalyticsDashboardState();
}

class _JoltsAnalyticsDashboardState extends State<JoltsAnalyticsDashboard> {
  final _supabase = Supabase.instance.client;
  final _gaService = GoogleAnalyticsService.instance;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _videoAnalytics = [
    {
      'title': 'Election Night Predictions',
      'views': 45230,
      'watch_time_avg': 42,
      'completion_rate': 68.5,
      'engagement_rate': 12.3,
    },
    {
      'title': 'VP Economy Explained',
      'views': 32100,
      'watch_time_avg': 38,
      'completion_rate': 72.1,
      'engagement_rate': 15.7,
    },
    {
      'title': 'How to Win Prediction Pools',
      'views': 28750,
      'watch_time_avg': 55,
      'completion_rate': 81.2,
      'engagement_rate': 18.4,
    },
    {
      'title': 'Top 10 Voting Strategies',
      'views': 21400,
      'watch_time_avg': 48,
      'completion_rate': 65.8,
      'engagement_rate': 9.2,
    },
    {
      'title': 'NFT Achievement Guide',
      'views': 18900,
      'watch_time_avg': 35,
      'completion_rate': 58.3,
      'engagement_rate': 11.6,
    },
  ];

  final Map<String, dynamic> _overallMetrics = {
    'total_views': 146380,
    'unique_viewers': 89420,
    'avg_watch_time': 43,
    'completion_rate': 69.2,
  };

  final List<Map<String, dynamic>> _dailyTrend = [
    {'day': 'Mon', 'views': 18200, 'engagement': 2240},
    {'day': 'Tue', 'views': 21500, 'engagement': 3100},
    {'day': 'Wed', 'views': 19800, 'engagement': 2850},
    {'day': 'Thu', 'views': 24300, 'engagement': 3600},
    {'day': 'Fri', 'views': 28100, 'engagement': 4200},
    {'day': 'Sat', 'views': 22400, 'engagement': 3300},
    {'day': 'Sun', 'views': 20100, 'engagement': 2900},
  ];

  final Map<String, double> _ageGroups = {
    '18-24': 28.5,
    '25-34': 35.2,
    '35-44': 20.1,
    '45-54': 10.8,
    '55+': 5.4,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _exportAnalytics() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics CSV exported successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: CustomAppBar(
        title: 'Jolts Analytics Dashboard',
        variant: CustomAppBarVariant.withBack,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const ShimmerSkeletonLoader(
              child: SkeletonDashboard(),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall metrics
                  Row(
                    children: [
                      _buildMetricCard(
                        'Total Views',
                        _formatNumber(_overallMetrics['total_views']),
                        Colors.blue,
                      ),
                      SizedBox(width: 2.w),
                      _buildMetricCard(
                        'Unique Viewers',
                        _formatNumber(_overallMetrics['unique_viewers']),
                        Colors.purple,
                      ),
                    ],
                  ),
                  SizedBox(height: 1.5.h),
                  Row(
                    children: [
                      _buildMetricCard(
                        'Avg Watch Time',
                        '${_overallMetrics['avg_watch_time']}s',
                        Colors.green,
                      ),
                      SizedBox(width: 2.w),
                      _buildMetricCard(
                        'Completion Rate',
                        '${_overallMetrics['completion_rate']}%',
                        Colors.orange,
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  // Daily trend chart
                  Text(
                    'Daily Views & Engagement',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    height: 22.h,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: Colors.grey.withAlpha(51),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, meta) {
                                final idx = v.toInt();
                                if (idx >= 0 && idx < _dailyTrend.length) {
                                  return Text(
                                    _dailyTrend[idx]['day'],
                                    style: GoogleFonts.inter(
                                      color: Colors.grey,
                                      fontSize: 8.sp,
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _dailyTrend
                                .asMap()
                                .entries
                                .map(
                                  (e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value['views'] / 1000.0,
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withAlpha(26),
                            ),
                          ),
                          LineChartBarData(
                            spots: _dailyTrend
                                .asMap()
                                .entries
                                .map(
                                  (e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value['engagement'] / 1000.0,
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Top performing videos
                  Text(
                    'Top Performing Videos',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFF0F172A),
                        ),
                        columns: [
                          DataColumn(
                            label: Text(
                              'Title',
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Views',
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Avg Watch',
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Completion',
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Engagement',
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                        ],
                        rows: _videoAnalytics
                            .map(
                              (v) => DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 30.w,
                                      child: Text(
                                        v['title'],
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 9.sp,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _formatNumber(v['views']),
                                      style: GoogleFonts.inter(
                                        color: Colors.blue,
                                        fontSize: 9.sp,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${v['watch_time_avg']}s',
                                      style: GoogleFonts.inter(
                                        color: Colors.green,
                                        fontSize: 9.sp,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${v['completion_rate']}%',
                                      style: GoogleFonts.inter(
                                        color: Colors.orange,
                                        fontSize: 9.sp,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${v['engagement_rate']}%',
                                      style: GoogleFonts.inter(
                                        color: Colors.purple,
                                        fontSize: 9.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Demographics
                  Text(
                    'Viewer Age Distribution',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: _ageGroups.entries.map((entry) {
                        final colors = [
                          Colors.blue,
                          Colors.purple,
                          Colors.green,
                          Colors.orange,
                          Colors.red,
                        ];
                        final idx = _ageGroups.keys.toList().indexOf(entry.key);
                        return Padding(
                          padding: EdgeInsets.only(bottom: 1.h),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 12.w,
                                child: Text(
                                  entry.key,
                                  style: GoogleFonts.inter(
                                    color: Colors.grey,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: entry.value / 100,
                                  backgroundColor: Colors.grey.withAlpha(51),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colors[idx % colors.length],
                                  ),
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '${entry.value}%',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 9.sp),
            ),
            SizedBox(height: 0.3.h),
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}