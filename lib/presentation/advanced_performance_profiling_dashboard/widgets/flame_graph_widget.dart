import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../services/performance_profiling_service.dart';
import '../../../theme/app_theme.dart';

class FlameGraphWidget extends StatefulWidget {
  final String screenName;

  const FlameGraphWidget({super.key, required this.screenName});

  @override
  State<FlameGraphWidget> createState() => _FlameGraphWidgetState();
}

class _FlameGraphWidgetState extends State<FlameGraphWidget> {
  final PerformanceProfilingService _profilingService =
      PerformanceProfilingService.instance;

  Map<String, dynamic>? _flameGraphData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlameGraphData();
  }

  @override
  void didUpdateWidget(FlameGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenName != widget.screenName) {
      _loadFlameGraphData();
    }
  }

  Future<void> _loadFlameGraphData() async {
    setState(() => _isLoading = true);

    final data = await _profilingService.getFlameGraphData(
      screenName: widget.screenName,
    );

    setState(() {
      _flameGraphData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_flameGraphData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 20.w,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 2.h),
            Text(
              'No flame graph data available',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Flame graphs will be generated during profiling sessions',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final hotSpots = List<Map<String, dynamic>>.from(
      _flameGraphData!['hot_spots'] ?? [],
    );
    final totalBuildTime = _flameGraphData!['total_build_time_ms'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 8.w,
                  color: Colors.orange,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Build Time',
                        style: google_fonts.GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      Text(
                        '${totalBuildTime.toStringAsFixed(2)} ms',
                        style: google_fonts.GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Performance Hot Spots',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (hotSpots.isEmpty)
            Center(
              child: Text(
                'No hot spots detected',
                style: google_fonts.GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            )
          else
            ...hotSpots.map((hotSpot) => _buildHotSpotCard(hotSpot)),
        ],
      ),
    );
  }

  Widget _buildHotSpotCard(Map<String, dynamic> hotSpot) {
    final widgetName = hotSpot['widget_name'] ?? 'Unknown Widget';
    final buildTime = hotSpot['build_time_ms'] ?? 0;
    final percentage = hotSpot['percentage'] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.widgets, size: 5.w, color: AppTheme.primaryLight),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    widgetName,
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getHotSpotColor(percentage),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Build Time: ${buildTime.toStringAsFixed(2)} ms',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHotSpotColor(double percentage) {
    if (percentage > 30) return Colors.red;
    if (percentage > 15) return Colors.orange;
    return Colors.yellow.shade700;
  }
}
