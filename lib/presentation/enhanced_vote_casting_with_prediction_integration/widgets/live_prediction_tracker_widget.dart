import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Live prediction tracker showing user prediction vs crowd graph
class LivePredictionTrackerWidget extends StatefulWidget {
  final String electionId;
  final Map<String, double> userPredictions;
  final List<Map<String, dynamic>> options;

  const LivePredictionTrackerWidget({
    super.key,
    required this.electionId,
    required this.userPredictions,
    required this.options,
  });

  @override
  State<LivePredictionTrackerWidget> createState() =>
      _LivePredictionTrackerWidgetState();
}

class _LivePredictionTrackerWidgetState
    extends State<LivePredictionTrackerWidget> {
  Map<String, double> _liveCrowdPredictions = {};
  int _userRank = 12;
  final int _totalPredictors = 150;
  Timer? _refreshTimer;
  List<FlSpot> _userSpots = [];
  List<FlSpot> _crowdSpots = [];
  double _timeIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializePredictions();
    _startLiveUpdates();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _initializePredictions() {
    _liveCrowdPredictions = {};
    for (final opt in widget.options) {
      final optId = opt['id'] as String;
      _liveCrowdPredictions[optId] = widget.userPredictions[optId] != null
          ? (widget.userPredictions[optId]! + (10 - 20 * 0.5)).clamp(0, 100)
          : 50.0;
    }

    // Initialize chart data
    _userSpots = [FlSpot(0, 50)];
    _crowdSpots = [FlSpot(0, 50)];
    _timeIndex = 1;
  }

  void _startLiveUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          // Keep tracker deterministic in production paths until realtime
          // crowd stream is available.

          // Update chart
          final firstOptId = widget.options.isNotEmpty
              ? widget.options[0]['id'] as String
              : '';
          final userVal = widget.userPredictions[firstOptId] ?? 50.0;
          final crowdVal = _liveCrowdPredictions[firstOptId] ?? 50.0;

          _userSpots.add(FlSpot(_timeIndex, userVal));
          _crowdSpots.add(FlSpot(_timeIndex, crowdVal));

          if (_userSpots.length > 10) _userSpots.removeAt(0);
          if (_crowdSpots.length > 10) _crowdSpots.removeAt(0);

          _timeIndex++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Prediction Tracker',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'LIVE',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),

          // Rank indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.leaderboard,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                SizedBox(width: 2.w),
                Text(
                  "You're #$_userRank of $_totalPredictors predictors",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Chart
          SizedBox(
            height: 15.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _userSpots.isEmpty
                        ? [const FlSpot(0, 50)]
                        : _userSpots,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: _crowdSpots.isEmpty
                        ? [const FlSpot(0, 50)]
                        : _crowdSpots,
                    isCurved: true,
                    color: theme.colorScheme.secondary,
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.h),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                context,
                'Your Prediction',
                theme.colorScheme.primary,
                false,
              ),
              SizedBox(width: 4.w),
              _buildLegendItem(
                context,
                'Crowd Average',
                theme.colorScheme.secondary,
                true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color color,
    bool isDashed,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            border: isDashed ? Border.all(color: color, width: 1) : null,
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}
