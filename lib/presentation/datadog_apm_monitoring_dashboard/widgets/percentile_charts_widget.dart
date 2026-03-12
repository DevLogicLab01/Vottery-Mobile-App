import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_service.dart';

class PercentileChartsWidget extends StatefulWidget {
  const PercentileChartsWidget({super.key});

  @override
  State<PercentileChartsWidget> createState() => _PercentileChartsWidgetState();
}

class _PercentileChartsWidgetState extends State<PercentileChartsWidget>
    with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService.instance.client;
  late TabController _tabController;
  Map<String, List<FlSpot>> _p50Data = {};
  Map<String, List<FlSpot>> _p95Data = {};
  Map<String, List<FlSpot>> _p99Data = {};
  List<String> _systems = [];
  bool _isLoading = true;
  String _timeRange = '24h';
  Timer? _refreshTimer;

  static const List<Color> _systemColors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
    Color(0xFF795548),
    Color(0xFF009688),
    Color(0xFFFFC107),
    Color(0xFF3F51B5),
  ];

  // SLA threshold for P95
  static const double _p95SlaThreshold = 500.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadData(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final cutoff = _timeRange == '24h'
          ? DateTime.now().subtract(const Duration(hours: 24))
          : DateTime.now().subtract(const Duration(days: 7));

      final data = await _supabase
          .from('datadog_trace_metadata')
          .select(
            'system_name, latency_p50, latency_p95, latency_p99, recorded_at',
          )
          .gte('recorded_at', cutoff.toIso8601String())
          .order('recorded_at', ascending: true)
          .limit(1000);

      final systemSet = <String>{};
      final Map<String, List<Map<String, dynamic>>> bySystem = {};

      for (final row in data) {
        final sys = row['system_name'] as String;
        systemSet.add(sys);
        bySystem.putIfAbsent(sys, () => []).add(row);
      }

      final systems = systemSet.toList()..sort();
      final Map<String, List<FlSpot>> p50 = {};
      final Map<String, List<FlSpot>> p95 = {};
      final Map<String, List<FlSpot>> p99 = {};

      for (final sys in systems) {
        final rows = bySystem[sys] ?? [];
        p50[sys] = [];
        p95[sys] = [];
        p99[sys] = [];
        for (int i = 0; i < rows.length; i++) {
          final x = i.toDouble();
          p50[sys]!.add(FlSpot(x, (rows[i]['latency_p50'] ?? 100).toDouble()));
          p95[sys]!.add(FlSpot(x, (rows[i]['latency_p95'] ?? 200).toDouble()));
          p99[sys]!.add(FlSpot(x, (rows[i]['latency_p99'] ?? 400).toDouble()));
        }
      }

      if (mounted) {
        setState(() {
          _systems = systems;
          _p50Data = p50;
          _p95Data = p95;
          _p99Data = p99;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Percentile chart error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Percentile Charts',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      _buildTimeRangeButton('24h'),
                      const SizedBox(width: 8),
                      _buildTimeRangeButton('7d'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF632CA6),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF632CA6),
                tabs: const [
                  Tab(text: 'P50'),
                  Tab(text: 'P95'),
                  Tab(text: 'P99'),
                ],
              ),
              SizedBox(height: 1.h),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SizedBox(
                      height: 30.h,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildChart(_p50Data, 'P50 Latency', showSLA: false),
                          _buildChart(_p95Data, 'P95 Latency', showSLA: true),
                          _buildChart(_p99Data, 'P99 Latency', showSLA: false),
                        ],
                      ),
                    ),
              SizedBox(height: 1.h),
              // Legend
              if (_systems.isNotEmpty) _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeButton(String range) {
    final isSelected = _timeRange == range;
    return GestureDetector(
      onTap: () {
        setState(() => _timeRange = range);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF632CA6) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          range,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(
    Map<String, List<FlSpot>> data,
    String title, {
    bool showSLA = false,
  }) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final lines = <LineChartBarData>[];
    int colorIdx = 0;
    for (final sys in _systems) {
      final spots = data[sys];
      if (spots == null || spots.isEmpty) {
        colorIdx++;
        continue;
      }
      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _systemColors[colorIdx % _systemColors.length],
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: showSLA,
            color: spots.any((s) => s.y > _p95SlaThreshold)
                ? Colors.red.withAlpha(25)
                : Colors.transparent,
          ),
        ),
      );
      colorIdx++;
    }

    double maxY = 1000;
    for (final spots in data.values) {
      for (final s in spots) {
        if (s.y > maxY) maxY = s.y;
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}ms',
                style: TextStyle(fontSize: 9.sp, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        lineBarsData: lines,
        minY: 0,
        maxY: maxY * 1.2,
        extraLinesData: showSLA
            ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: _p95SlaThreshold,
                    color: Colors.red,
                    strokeWidth: 1.5,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      labelResolver: (_) => 'SLA 500ms',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            : const ExtraLinesData(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final sysName = _systems.length > spot.barIndex
                    ? _systems[spot.barIndex]
                    : 'System';
                return LineTooltipItem(
                  '$sysName\n${spot.y.toInt()}ms',
                  TextStyle(
                    color: _systemColors[spot.barIndex % _systemColors.length],
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: _systems.asMap().entries.map((e) {
        final color = _systemColors[e.key % _systemColors.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 3, color: color),
            const SizedBox(width: 4),
            Text(
              e.value.length > 15 ? e.value.substring(0, 15) : e.value,
              style: TextStyle(fontSize: 10.sp),
            ),
          ],
        );
      }).toList(),
    );
  }
}
