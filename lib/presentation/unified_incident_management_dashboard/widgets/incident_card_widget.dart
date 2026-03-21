import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/app_export.dart';
import '../../../services/unified_incident_aggregator_service.dart';
import '../../../theme/app_theme.dart';

class IncidentCardWidget extends StatelessWidget {
  final UnifiedIncident incident;
  final VoidCallback onTap;
  final VoidCallback onTriage;
  final VoidCallback onInvestigate;
  final VoidCallback onResolve;
  final VoidCallback onAssign;
  final VoidCallback onEscalate;

  const IncidentCardWidget({
    super.key,
    required this.incident,
    required this.onTap,
    required this.onTriage,
    required this.onInvestigate,
    required this.onResolve,
    required this.onAssign,
    required this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    final priority = incident.priorityScore != null
        ? (incident.priorityScore! > 90
              ? 'P0'
              : incident.priorityScore! >= 70
              ? 'P1'
              : incident.priorityScore! >= 50
              ? 'P2'
              : 'P3')
        : 'P2';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Severity badge
                  _buildSeverityBadge(incident.severity),
                  SizedBox(width: 2.w),

                  // Incident type icon
                  _buildIncidentTypeIcon(incident.incidentType),
                  SizedBox(width: 2.w),

                  // Title
                  Expanded(
                    child: Text(
                      incident.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Age
                  Text(
                    timeago.format(incident.detectedAt),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.h),

              // Description
              Text(
                incident.description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 1.5.h),

              // Metadata row
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: [
                  _buildChip(
                    'Source: ${incident.sourceSystem}',
                    AppTheme.secondaryLight,
                  ),
                  _buildChip(
                    'Priority: $priority',
                    _getPriorityColor(priority),
                  ),
                  if (incident.affectedResources.isNotEmpty)
                    _buildChip(
                      '${incident.affectedResources.length} resources',
                      AppTheme.warningLight,
                    ),
                  _buildStatusBadge(incident.status),
                ],
              ),

              SizedBox(height: 1.5.h),

              // Action buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onAssign,
                    icon: Icon(Icons.person_add, size: 4.w),
                    label: Text('Assign', style: TextStyle(fontSize: 10.sp)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  OutlinedButton.icon(
                    onPressed: onEscalate,
                    icon: Icon(Icons.priority_high, size: 4.w),
                    label: Text('Escalate', style: TextStyle(fontSize: 10.sp)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  if (incident.status == IncidentStatus.newIncident)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTriage,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                        ),
                        child: Text(
                          'Triage',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                    ),
                  if (incident.status == IncidentStatus.triaged)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onInvestigate,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                        ),
                        child: Text(
                          'Investigate',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                    ),
                  if (incident.status == IncidentStatus.investigating)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onResolve,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentLight,
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                        ),
                        child: Text(
                          'Resolve',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                    ),
                  SizedBox(width: 2.w),
                  OutlinedButton.icon(
                    onPressed: onTap,
                    icon: Icon(Icons.arrow_forward, size: 4.w),
                    label: Text('Details', style: TextStyle(fontSize: 11.sp)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(IncidentSeverity severity) {
    Color color;
    String label;

    switch (severity) {
      case IncidentSeverity.critical:
        color = AppTheme.errorLight;
        label = 'CRITICAL';
        break;
      case IncidentSeverity.high:
        color = Colors.orange;
        label = 'HIGH';
        break;
      case IncidentSeverity.medium:
        color = AppTheme.warningLight;
        label = 'MEDIUM';
        break;
      case IncidentSeverity.low:
        color = AppTheme.accentLight;
        label = 'LOW';
        break;
    }

    return Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          label[0],
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentTypeIcon(IncidentType type) {
    IconData icon;
    Color color;

    switch (type) {
      case IncidentType.fraud:
        icon = Icons.security;
        color = AppTheme.errorLight;
        break;
      case IncidentType.aiFailover:
        icon = Icons.autorenew;
        color = Colors.purple;
        break;
      case IncidentType.security:
        icon = Icons.shield;
        color = Colors.red;
        break;
      case IncidentType.performance:
        icon = Icons.speed;
        color = Colors.orange;
        break;
      case IncidentType.health:
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      case IncidentType.compliance:
        icon = Icons.policy;
        color = Colors.blue;
        break;
    }

    return Icon(icon, size: 5.w, color: color);
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.sp, color: color),
      ),
    );
  }

  Widget _buildStatusBadge(IncidentStatus status) {
    Color color;
    String label;

    switch (status) {
      case IncidentStatus.newIncident:
        color = AppTheme.warningLight;
        label = 'New';
        break;
      case IncidentStatus.triaged:
        color = AppTheme.secondaryLight;
        label = 'Triaged';
        break;
      case IncidentStatus.investigating:
        color = Colors.purple;
        label = 'Investigating';
        break;
      case IncidentStatus.resolved:
        color = AppTheme.accentLight;
        label = 'Resolved';
        break;
      case IncidentStatus.escalated:
        color = AppTheme.errorLight;
        label = 'Escalated';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'P0':
        return AppTheme.errorLight;
      case 'P1':
        return Colors.orange;
      case 'P2':
        return AppTheme.warningLight;
      case 'P3':
        return AppTheme.accentLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }
}
