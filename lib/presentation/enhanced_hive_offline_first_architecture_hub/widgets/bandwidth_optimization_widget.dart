import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BandwidthOptimizationWidget extends StatelessWidget {
  final double dataReduction;
  final int totalBytes;
  final int compressedBytes;

  const BandwidthOptimizationWidget({
    super.key,
    required this.dataReduction,
    required this.totalBytes,
    required this.compressedBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bandwidth Optimization',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Delta-sync with gzip compression',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDataMetric(
                  'Original',
                  _formatBytes(totalBytes),
                  Colors.red,
                ),
                Icon(Icons.arrow_forward, color: Colors.grey, size: 24.sp),
                _buildDataMetric(
                  'Compressed',
                  _formatBytes(compressedBytes),
                  Colors.green,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: dataReduction / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 1.h,
            ),
            SizedBox(height: 1.h),
            Center(
              child: Text(
                '${dataReduction.toStringAsFixed(1)}% Data Reduction',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
