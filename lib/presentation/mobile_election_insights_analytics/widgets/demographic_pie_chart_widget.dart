import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DemographicPieChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> demographics;

  const DemographicPieChartWidget({super.key, required this.demographics});

  @override
  State<DemographicPieChartWidget> createState() =>
      _DemographicPieChartWidgetState();
}

class _DemographicPieChartWidgetState extends State<DemographicPieChartWidget> {
  String _selectedType = 'age';

  List<Map<String, dynamic>> get _filteredDemographics {
    return widget.demographics
        .where((d) => d['demographic_type'] == _selectedType)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.demographics.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Center(
            child: Text(
              'No demographic data available',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demographic Breakdown',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),

            // Type Selector
            Wrap(
              spacing: 2.w,
              children: ['age', 'gender', 'location', 'zone'].map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 2.h),

            // Pie Chart
            if (_filteredDemographics.isNotEmpty)
              SizedBox(
                height: 30.h,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: _filteredDemographics.map((demo) {
                            final percentage =
                                (demo['percentage'] as num?)?.toDouble() ?? 0.0;
                            final color = _getColorForIndex(
                              _filteredDemographics.indexOf(demo),
                            );

                            return PieChartSectionData(
                              value: percentage,
                              title: '${percentage.toStringAsFixed(1)}%',
                              color: color,
                              radius: 50,
                              titleStyle: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _filteredDemographics.map((demo) {
                          final value = demo['demographic_value'] as String;
                          final color = _getColorForIndex(
                            _filteredDemographics.indexOf(demo),
                          );

                          return Padding(
                            padding: EdgeInsets.only(bottom: 1.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 3.w,
                                  height: 3.w,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(
                                    value,
                                    style: TextStyle(fontSize: 10.sp),
                                    overflow: TextOverflow.ellipsis,
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
              )
            else
              Center(
                child: Text(
                  'No data for $_selectedType',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
}
