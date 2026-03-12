import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PerformanceMetricsPanelWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onStatusUpdate;
  const PerformanceMetricsPanelWidget({
    super.key,
    required this.onStatusUpdate,
  });
  @override
  State<PerformanceMetricsPanelWidget> createState() =>
      _PerformanceMetricsPanelWidgetState();
}

class _PerformanceMetricsPanelWidgetState
    extends State<PerformanceMetricsPanelWidget> {
  bool _isMeasuring = false;
  final List<Map<String, dynamic>> _metrics = [
    {
      'name': 'Bundle Size',
      'current': '38.2 MB',
      'target': '35 MB',
      'currentVal': 38.2,
      'targetVal': 35.0,
      'lowerIsBetter': true,
    },
    {
      'name': 'Memory Usage',
      'current': '142 MB',
      'target': '150 MB',
      'currentVal': 142.0,
      'targetVal': 150.0,
      'lowerIsBetter': true,
    },
    {
      'name': 'Frame Rate',
      'current': '58 FPS',
      'target': '60 FPS',
      'currentVal': 58.0,
      'targetVal': 60.0,
      'lowerIsBetter': false,
    },
    {
      'name': 'Cold Start',
      'current': '2.1s',
      'target': '2.0s',
      'currentVal': 2.1,
      'targetVal': 2.0,
      'lowerIsBetter': true,
    },
    {
      'name': 'Warm Start',
      'current': '0.8s',
      'target': '1.0s',
      'currentVal': 0.8,
      'targetVal': 1.0,
      'lowerIsBetter': true,
    },
    {
      'name': 'API Latency',
      'current': '185ms',
      'target': '200ms',
      'currentVal': 185.0,
      'targetVal': 200.0,
      'lowerIsBetter': true,
    },
  ];

  bool _meetsTarget(Map<String, dynamic> metric) {
    final current = metric['currentVal'] as double;
    final target = metric['targetVal'] as double;
    final lowerIsBetter = metric['lowerIsBetter'] as bool;
    return lowerIsBetter ? current <= target : current >= target;
  }

  Future<void> _measurePerformance() async {
    setState(() => _isMeasuring = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isMeasuring = false);
    final passed = _metrics.where(_meetsTarget).length;
    widget.onStatusUpdate({
      'passed': passed,
      'total': _metrics.length,
      'score': (passed / _metrics.length * 100).round(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              onPressed: _isMeasuring ? null : _measurePerformance,
              icon: _isMeasuring
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.speed, size: 16),
              label: Text(
                _isMeasuring ? 'Measuring...' : 'Measure',
                style: TextStyle(fontSize: 11.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 3.w,
            headingRowHeight: 4.h,
            dataRowMinHeight: 5.h,
            dataRowMaxHeight: 6.h,
            columns: [
              DataColumn(
                label: Text(
                  'Metric',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Current',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Target',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            rows: _metrics.map((metric) {
              final meets = _meetsTarget(metric);
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      metric['name'] as String,
                      style: TextStyle(fontSize: 11.sp),
                    ),
                  ),
                  DataCell(
                    Text(
                      metric['current'] as String,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: meets
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      metric['target'] as String,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: meets
                            ? const Color(0xFF10B981).withAlpha(26)
                            : const Color(0xFFEF4444).withAlpha(26),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        meets ? 'PASS' : 'FAIL',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: meets
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
