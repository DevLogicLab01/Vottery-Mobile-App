import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class ErrorIncidentCardWidget extends StatelessWidget {
  final Map<String, dynamic> incident;
  final Function(String incidentId, String status) onUpdateStatus;

  const ErrorIncidentCardWidget({
    super.key,
    required this.incident,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorType = incident['error_type'] as String? ?? 'unknown';
    final severity = incident['severity'] as String? ?? 'low';
    final affectedFeature = incident['affected_feature'] as String?;
    final errorMessage = incident['error_message'] as String? ?? 'No message';
    final status = incident['status'] as String? ?? 'open';
    final occurredAt = incident['occurred_at'] as String?;
    final incidentId = incident['incident_id'] as String?;

    Color severityColor;
    switch (severity) {
      case 'critical':
        severityColor = Colors.red;
        break;
      case 'high':
        severityColor = Colors.orange;
        break;
      case 'medium':
        severityColor = Colors.yellow.shade700;
        break;
      default:
        severityColor = Colors.blue;
    }

    Color statusColor;
    switch (status) {
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: severityColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              severity.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: severityColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              errorType.replaceAll('_', ' ').toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      if (affectedFeature != null)
                        Text(
                          'Feature: ${affectedFeature.replaceAll('_', ' ').toUpperCase()}',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              errorMessage,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
                SizedBox(width: 1.w),
                Text(
                  occurredAt != null
                      ? timeago.format(DateTime.parse(occurredAt))
                      : 'Unknown time',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
            if (status != 'resolved' && incidentId != null) ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          onUpdateStatus(incidentId, 'in_progress'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue),
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                      ),
                      child: Text(
                        'In Progress',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onUpdateStatus(incidentId, 'resolved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                      ),
                      child: Text(
                        'Resolve',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
