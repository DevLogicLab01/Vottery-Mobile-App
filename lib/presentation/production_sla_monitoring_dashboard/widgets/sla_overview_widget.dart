import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SlaOverviewWidget extends StatelessWidget {
  final Map<String, dynamic> uptimeData;

  const SlaOverviewWidget({super.key, required this.uptimeData});

  @override
  Widget build(BuildContext context) {
    final uptimePercentage = uptimeData['uptime_percentage'] ?? 100.0;
    final targetSLA = uptimeData['target_sla'] ?? 99.9;
    final slaStatus = uptimeData['sla_status'] ?? 'on_track';
    final remainingBudget = uptimeData['remaining_budget_minutes'] ?? 43.2;
    final totalDowntime = uptimeData['total_downtime_minutes'] ?? 0.0;
    final daysUntilReset = uptimeData['days_until_reset'] ?? 30;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (slaStatus) {
      case 'on_track':
        statusColor = Colors.green;
        statusLabel = 'On Track';
        statusIcon = Icons.check_circle;
        break;
      case 'at_risk':
        statusColor = Colors.orange;
        statusLabel = 'At Risk';
        statusIcon = Icons.warning;
        break;
      case 'breached':
        statusColor = Colors.red;
        statusLabel = 'Breached';
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'Unknown';
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SLA Compliance Overview',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 16.sp, color: statusColor),
                      SizedBox(width: 1.w),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildUptimeGauge(uptimePercentage, statusColor),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetricRow(
                        'Target SLA',
                        '${targetSLA.toStringAsFixed(1)}%',
                        Icons.flag,
                        Colors.blue,
                      ),
                      SizedBox(height: 1.h),
                      _buildMetricRow(
                        'Total Downtime',
                        '${totalDowntime.toStringAsFixed(1)} min',
                        Icons.schedule,
                        Colors.orange,
                      ),
                      SizedBox(height: 1.h),
                      _buildMetricRow(
                        'Days Until Reset',
                        '$daysUntilReset days',
                        Icons.calendar_today,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Text(
              'Remaining Downtime Budget',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            _buildBudgetProgressBar(remainingBudget, totalDowntime),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Used: ${totalDowntime.toStringAsFixed(1)} min',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                Text(
                  'Remaining: ${remainingBudget.toStringAsFixed(1)} min',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUptimeGauge(double percentage, Color color) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: 270,
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: percentage,
                  color: color,
                  radius: 20,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: 100 - percentage,
                  color: Colors.grey[200],
                  radius: 20,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'Uptime',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetProgressBar(double remaining, double used) {
    final total = 43.2;
    final usedPercentage = (used / total).clamp(0.0, 1.0);

    return LinearProgressIndicator(
      value: usedPercentage,
      backgroundColor: Colors.green[100],
      valueColor: AlwaysStoppedAnimation<Color>(
        usedPercentage > 0.9
            ? Colors.red
            : usedPercentage > 0.7
            ? Colors.orange
            : Colors.green,
      ),
      minHeight: 10,
    );
  }
}
