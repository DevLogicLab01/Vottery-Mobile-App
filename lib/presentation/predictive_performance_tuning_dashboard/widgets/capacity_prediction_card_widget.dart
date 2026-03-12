import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class CapacityPredictionCardWidget extends StatelessWidget {
  final String timeframe;
  final int predictedUsers;
  final int predictedConnections;
  final double predictedMemory;
  final double confidenceScore;

  const CapacityPredictionCardWidget({
    super.key,
    required this.timeframe,
    required this.predictedUsers,
    required this.predictedConnections,
    required this.predictedMemory,
    required this.confidenceScore,
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
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.purple[600], size: 18),
                SizedBox(width: 2.w),
                Text(
                  '$timeframe Prediction',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    '${(confidenceScore * 100).toInt()}% confidence',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPredictionItem(
                  'Users',
                  '${(predictedUsers / 1000).toStringAsFixed(1)}K',
                  Icons.people,
                  Colors.blue,
                ),
                _buildPredictionItem(
                  'DB Connections',
                  '$predictedConnections',
                  Icons.storage,
                  Colors.orange,
                ),
                _buildPredictionItem(
                  'Memory',
                  '${predictedMemory.toStringAsFixed(0)}%',
                  Icons.memory,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
