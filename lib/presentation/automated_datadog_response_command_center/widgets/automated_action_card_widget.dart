import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AutomatedActionCardWidget extends StatelessWidget {
  final String actionName;
  final String description;
  final String trigger;
  final String status;
  final String lastExecuted;
  final VoidCallback? onExecute;

  const AutomatedActionCardWidget({
    super.key,
    required this.actionName,
    required this.description,
    required this.trigger,
    required this.status,
    required this.lastExecuted,
    this.onExecute,
  });

  Color get _statusColor {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'triggered':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

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
                Expanded(
                  child: Text(
                    actionName,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Icon(Icons.bolt, size: 14, color: Colors.amber[700]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Trigger: $trigger',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onExecute != null)
                  TextButton(
                    onPressed: onExecute,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'Execute',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              'Last: $lastExecuted',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
