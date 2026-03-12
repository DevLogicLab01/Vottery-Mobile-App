import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class InjectionQueueWidget extends StatelessWidget {
  final List<Map<String, dynamic>> injectionQueue;
  final Function(String) onBroadcast;
  final Function(String) onDelete;
  final Function(String, Map<String, dynamic>) onEdit;

  const InjectionQueueWidget({
    super.key,
    required this.injectionQueue,
    required this.onBroadcast,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (injectionQueue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue, size: 20.w, color: Colors.grey.shade300),
            SizedBox(height: 2.h),
            Text(
              'No questions in queue',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: injectionQueue.length,
      itemBuilder: (context, index) {
        final question = injectionQueue[index];
        return _buildQuestionCard(context, question);
      },
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    Map<String, dynamic> question,
  ) {
    final status = question['injection_status'] ?? 'pending';
    final createdAt = DateTime.parse(question['created_at']);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(status),
                const Spacer(),
                Text(
                  _formatDateTime(createdAt),
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              question['question_text'] ?? '',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              children: [
                _buildInfoChip(
                  Icons.list,
                  '${(question['options'] as List).length} options',
                  Colors.blue,
                ),
                _buildInfoChip(
                  Icons.signal_cellular_alt,
                  question['difficulty_level'] ?? 'medium',
                  Colors.orange,
                ),
                _buildInfoChip(
                  Icons.location_on,
                  question['injection_position'] ?? 'end',
                  Colors.purple,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                if (status == 'pending') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onBroadcast(question['id']),
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Broadcast Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentLight,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                ],
                IconButton(
                  onPressed: () => onDelete(question['id']),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.schedule;
        label = 'PENDING';
        break;
      case 'scheduled':
        color = Colors.blue;
        icon = Icons.event;
        label = 'SCHEDULED';
        break;
      case 'broadcasted':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'BROADCASTED';
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        label = 'CANCELLED';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        label = 'UNKNOWN';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.w, color: color),
          SizedBox(width: 1.w),
          Text(
            label,
            style: google_fonts.GoogleFonts.inter(
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.w, color: color),
          SizedBox(width: 1.w),
          Text(
            label,
            style: google_fonts.GoogleFonts.inter(fontSize: 9.sp, color: color),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
