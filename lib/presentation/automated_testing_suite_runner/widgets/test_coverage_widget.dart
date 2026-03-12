import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class TestCoverageWidget extends StatelessWidget {
  final Map<String, dynamic> coverageData;

  const TestCoverageWidget({super.key, required this.coverageData});

  @override
  Widget build(BuildContext context) {
    final unitCoverage = coverageData['unit_test_coverage'] ?? 0.0;
    final integrationCoverage =
        coverageData['integration_test_coverage'] ?? 0.0;
    final e2eCoverage = coverageData['e2e_test_coverage'] ?? 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Coverage',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Track unit, integration, and E2E test coverage with target 80%+',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          _buildCoverageCard(
            'Unit Test Coverage',
            unitCoverage,
            Icons.code,
            Colors.blue,
            80.0,
          ),
          SizedBox(height: 2.h),
          _buildCoverageCard(
            'Integration Test Coverage',
            integrationCoverage,
            Icons.integration_instructions,
            Colors.green,
            75.0,
          ),
          SizedBox(height: 2.h),
          _buildCoverageCard(
            'E2E Test Coverage',
            e2eCoverage,
            Icons.devices,
            Colors.orange,
            70.0,
          ),
          SizedBox(height: 3.h),
          _buildCoverageChart(unitCoverage, integrationCoverage, e2eCoverage),
        ],
      ),
    );
  }

  Widget _buildCoverageCard(
    String title,
    double coverage,
    IconData icon,
    Color color,
    double target,
  ) {
    final meetsTarget = coverage >= target;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Target: ${target.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${coverage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: meetsTarget ? Colors.green : Colors.orange,
                      ),
                    ),
                    Icon(
                      meetsTarget ? Icons.check_circle : Icons.warning,
                      color: meetsTarget ? Colors.green : Colors.orange,
                      size: 20.sp,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: coverage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                meetsTarget ? Colors.green : Colors.orange,
              ),
              minHeight: 1.h,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageChart(double unit, double integration, double e2e) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coverage Breakdown',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 25.h,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return Text(
                                'Unit',
                                style: TextStyle(fontSize: 10.sp),
                              );
                            case 1:
                              return Text(
                                'Integration',
                                style: TextStyle(fontSize: 10.sp),
                              );
                            case 2:
                              return Text(
                                'E2E',
                                style: TextStyle(fontSize: 10.sp),
                              );
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: unit,
                          color: Colors.blue,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: integration,
                          color: Colors.green,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: e2e,
                          color: Colors.orange,
                          width: 20,
                        ),
                      ],
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
