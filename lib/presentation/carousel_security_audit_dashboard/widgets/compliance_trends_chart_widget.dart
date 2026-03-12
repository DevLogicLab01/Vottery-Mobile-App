import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../services/carousel_security_audit_service.dart';

class ComplianceTrendsChartWidget extends StatefulWidget {
  const ComplianceTrendsChartWidget({super.key});

  @override
  State<ComplianceTrendsChartWidget> createState() =>
      _ComplianceTrendsChartWidgetState();
}

class _ComplianceTrendsChartWidgetState
    extends State<ComplianceTrendsChartWidget> {
  final CarouselSecurityAuditService _auditService =
      CarouselSecurityAuditService.instance;

  List<Map<String, dynamic>> _trends = [];
  bool _isLoading = true;
  String? _selectedSystem;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    setState(() => _isLoading = true);

    final trends = await _auditService.getComplianceTrends(
      systemName: _selectedSystem,
    );

    if (mounted) {
      setState(() {
        _trends = trends;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Compliance Trends (30 Days)',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedSystem,
                  hint: Text('All Systems', style: TextStyle(fontSize: 12.sp)),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        'All Systems',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                    ...CarouselSecurityAuditService.carouselSystems
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, style: TextStyle(fontSize: 12.sp)),
                          ),
                        )
                        ,
                  ],
                  onChanged: (value) {
                    setState(() => _selectedSystem = value);
                    _loadTrends();
                  },
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _isLoading
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(4.h),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _trends.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(4.h),
                      child: Text(
                        'No trend data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 30.h,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(fontSize: 10.sp),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < _trends.length) {
                                  final date = DateTime.parse(
                                    _trends[value.toInt()]['calculated_at'],
                                  );
                                  return Text(
                                    '${date.day}/${date.month}',
                                    style: TextStyle(fontSize: 9.sp),
                                  );
                                }
                                return Text('');
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _trends
                                .asMap()
                                .entries
                                .map(
                                  (e) => FlSpot(
                                    e.key.toDouble(),
                                    (e.value['compliance_score'] as int)
                                        .toDouble(),
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3.0,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withAlpha(26),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
