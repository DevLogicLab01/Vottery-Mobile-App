import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/reconciliation_service.dart';

class ReconciliationReportsWidget extends StatefulWidget {
  final Map<String, dynamic> summary;
  final VoidCallback onRefresh;

  const ReconciliationReportsWidget({
    super.key,
    required this.summary,
    required this.onRefresh,
  });

  @override
  State<ReconciliationReportsWidget> createState() =>
      _ReconciliationReportsWidgetState();
}

class _ReconciliationReportsWidgetState
    extends State<ReconciliationReportsWidget> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rootCauses =
        widget.summary['root_causes'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range selector
          Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Date Range',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(context, true),
                          icon: Icon(Icons.calendar_today, size: 14.sp),
                          label: Text(
                            'Start: ${_startDate.toString().split(' ')[0]}',
                            style: TextStyle(fontSize: 10.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(context, false),
                          icon: Icon(Icons.calendar_today, size: 14.sp),
                          label: Text(
                            'End: ${_endDate.toString().split(' ')[0]}',
                            style: TextStyle(fontSize: 10.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Summary metrics
          Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        'Total',
                        '${widget.summary['total_discrepancies'] ?? 0}',
                        Colors.blue,
                      ),
                      _buildSummaryItem(
                        'Matched',
                        '${widget.summary['matched'] ?? 0}',
                        Colors.green,
                      ),
                      _buildSummaryItem(
                        'Unmatched',
                        '${widget.summary['unmatched'] ?? 0}',
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Root cause pie chart
          if (rootCauses.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Root Cause Distribution',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    SizedBox(
                      height: 30.h,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieChartSections(rootCauses),
                          centerSpaceRadius: 10.w,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ..._buildLegend(rootCauses),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],

          // Export button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exportReport,
              icon: Icon(Icons.download, size: 14.sp),
              label: Text('Export as CSV', style: TextStyle(fontSize: 12.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, dynamic> rootCauses,
  ) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
    ];
    int index = 0;

    return rootCauses.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;

      return PieChartSectionData(
        value: (entry.value as int).toDouble(),
        title: '${entry.value}',
        color: color,
        radius: 15.w,
        titleStyle: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend(Map<String, dynamic> rootCauses) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
    ];
    int index = 0;

    return rootCauses.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;

      return Padding(
        padding: EdgeInsets.only(bottom: 1.h),
        child: Row(
          children: [
            Container(
              width: 4.w,
              height: 4.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 2.w),
            Text(
              entry.key.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(fontSize: 10.sp),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      widget.onRefresh();
    }
  }

  Future<void> _exportReport() async {
    final discrepancies =
        widget.summary['discrepancies'] as List<Map<String, dynamic>>? ?? [];
    final success = await ReconciliationService.instance
        .exportTransactionsToCSV(transactions: discrepancies);

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Report exported successfully' : 'Export failed',
          ),
          // Remove action block
        ),
      );
    }
  }
}
