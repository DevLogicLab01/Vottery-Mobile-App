import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EngagementHeatmapGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> heatmapData;

  const EngagementHeatmapGridWidget({super.key, required this.heatmapData});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voter Engagement Heatmap',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'Peak voting times by hour and day',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),

            if (heatmapData.isEmpty)
              Center(
                child: Text(
                  'No heatmap data available',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              )
            else
              _buildHeatmapGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final hours = [0, 6, 12, 18];

    return Column(
      children: [
        // Hour labels
        Row(
          children: [
            SizedBox(width: 12.w),
            ...hours.map((hour) {
              return Expanded(
                child: Center(
                  child: Text(
                    '${hour}h',
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey),
                  ),
                ),
              );
            }),
          ],
        ),
        SizedBox(height: 1.h),

        // Heatmap grid
        ...List.generate(7, (dayIndex) {
          return Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Row(
              children: [
                SizedBox(
                  width: 12.w,
                  child: Text(
                    days[dayIndex],
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                  ),
                ),
                ...hours.map((hour) {
                  final intensity = _getIntensity(dayIndex, hour);
                  return Expanded(
                    child: Container(
                      height: 4.h,
                      margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                      decoration: BoxDecoration(
                        color: _getHeatmapColor(intensity),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
        SizedBox(height: 2.h),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Low', _getHeatmapColor(0)),
            SizedBox(width: 2.w),
            _buildLegendItem('Medium', _getHeatmapColor(50)),
            SizedBox(width: 2.w),
            _buildLegendItem('High', _getHeatmapColor(75)),
            SizedBox(width: 2.w),
            _buildLegendItem('Peak', _getHeatmapColor(100)),
          ],
        ),
      ],
    );
  }

  double _getIntensity(int dayOfWeek, int hourOfDay) {
    final data = heatmapData.firstWhere(
      (d) => d['day_of_week'] == dayOfWeek && d['hour_of_day'] == hourOfDay,
      orElse: () => {'intensity_score': 0.0},
    );
    return (data['intensity_score'] as num?)?.toDouble() ?? 0.0;
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity >= 75) return Colors.red.shade600;
    if (intensity >= 50) return Colors.orange.shade400;
    if (intensity >= 25) return Colors.green.shade300;
    return Colors.green.shade100;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: Colors.grey),
        ),
      ],
    );
  }
}
