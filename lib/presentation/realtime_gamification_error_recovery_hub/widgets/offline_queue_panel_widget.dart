import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/realtime_gamification_notification_service.dart';

class OfflineQueuePanelWidget extends StatefulWidget {
  final OfflineNotificationQueue queue;
  final VoidCallback onFlush;

  const OfflineQueuePanelWidget({
    super.key,
    required this.queue,
    required this.onFlush,
  });

  @override
  State<OfflineQueuePanelWidget> createState() =>
      _OfflineQueuePanelWidgetState();
}

class _OfflineQueuePanelWidgetState extends State<OfflineQueuePanelWidget> {
  @override
  Widget build(BuildContext context) {
    final pending = widget.queue.pending;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.queue, color: Colors.orange[600], size: 20),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Offline Queue',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pending.isEmpty
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${pending.length} pending',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: pending.isEmpty
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            if (pending.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green[400],
                        size: 32,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'No pending notifications',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ...pending
                      .take(3)
                      .map(
                        (n) => ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.notifications_paused,
                            size: 18,
                          ),
                          title: Text(
                            n.type,
                            style: GoogleFonts.inter(fontSize: 12.sp),
                          ),
                          subtitle: Text(
                            n.timestamp.toString().substring(0, 16),
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                  if (pending.length > 3)
                    Text(
                      '+${pending.length - 3} more...',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  SizedBox(height: 1.5.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onFlush,
                      icon: const Icon(Icons.send, size: 16),
                      label: Text(
                        'Flush Queue',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
