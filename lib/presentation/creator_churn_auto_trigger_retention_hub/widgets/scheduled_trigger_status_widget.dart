import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ScheduledTriggerStatusWidget extends StatelessWidget {
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;
  final int processedCount;
  final int pendingCount;
  final bool isRunning;
  final VoidCallback onRunNow;

  const ScheduledTriggerStatusWidget({
    super.key,
    this.lastRunAt,
    this.nextRunAt,
    required this.processedCount,
    required this.pendingCount,
    required this.isRunning,
    required this.onRunNow,
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
                Icon(Icons.schedule, color: Colors.indigo.shade700, size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Automated Trigger Schedule',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (isRunning)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.indigo.shade700,
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: onRunNow,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: Text('Run Now', style: TextStyle(fontSize: 9.sp)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.indigo.shade700,
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.indigo.shade700, size: 16),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Monitors creator_churn_predictions every 6 hours. Processes pending interventions where churn_probability > 0.5',
                      style: TextStyle(fontSize: 9.sp, color: Colors.indigo.shade700),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    'Last Run',
                    lastRunAt != null ? _formatTime(lastRunAt!) : 'Never',
                    Icons.history,
                    Colors.grey,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildTimeCard(
                    'Next Run',
                    nextRunAt != null ? _formatTime(nextRunAt!) : 'In 6 hours',
                    Icons.update,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: _buildCountCard('Processed', processedCount, Colors.green),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildCountCard('Pending', pendingCount, Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 1.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 8.sp, color: Colors.grey)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(fontSize: 9.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
