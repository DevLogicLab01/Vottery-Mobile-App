import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class AuditTrailVisualizationWidget extends StatefulWidget {
  final List<Map<String, dynamic>> auditTrail;

  const AuditTrailVisualizationWidget({super.key, required this.auditTrail});

  @override
  State<AuditTrailVisualizationWidget> createState() =>
      _AuditTrailVisualizationWidgetState();
}

class _AuditTrailVisualizationWidgetState
    extends State<AuditTrailVisualizationWidget> {
  String? _selectedJurisdiction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTrail = _selectedJurisdiction == null
        ? widget.auditTrail
        : widget.auditTrail
              .where((event) => event['jurisdiction'] == _selectedJurisdiction)
              .toList();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          color: theme.cardColor,
          child: Row(
            children: [
              Text(
                'Filter:',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Wrap(
                  spacing: 2.w,
                  children: [
                    FilterChip(
                      label: Text('All'),
                      selected: _selectedJurisdiction == null,
                      onSelected: (selected) {
                        setState(() => _selectedJurisdiction = null);
                      },
                    ),
                    FilterChip(
                      label: Text('GDPR'),
                      selected: _selectedJurisdiction == 'GDPR',
                      onSelected: (selected) {
                        setState(() => _selectedJurisdiction = 'GDPR');
                      },
                    ),
                    FilterChip(
                      label: Text('CCPA'),
                      selected: _selectedJurisdiction == 'CCPA',
                      onSelected: (selected) {
                        setState(() => _selectedJurisdiction = 'CCPA');
                      },
                    ),
                    FilterChip(
                      label: Text('CCRA'),
                      selected: _selectedJurisdiction == 'CCRA',
                      onSelected: (selected) {
                        setState(() => _selectedJurisdiction = 'CCRA');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredTrail.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: theme.colorScheme.onSurface.withAlpha(77),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No audit trail events',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: filteredTrail.length,
                  itemBuilder: (context, index) {
                    final event = filteredTrail[index];
                    return _buildAuditEventCard(context, event);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAuditEventCard(
    BuildContext context,
    Map<String, dynamic> event,
  ) {
    final theme = Theme.of(context);
    final actionType = event['action_type'] as String? ?? 'Unknown';
    final timestamp = event['timestamp'] as String?;
    final ipAddress = event['ip_address'] as String? ?? 'Unknown';
    final jurisdiction = event['jurisdiction'] as String?;
    final affectedRecords = event['affected_records'] as List? ?? [];

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
                  child: Text(
                    actionType.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (jurisdiction != null)
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
                      jurisdiction,
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
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
                SizedBox(width: 1.w),
                Text(
                  timestamp != null
                      ? timeago.format(DateTime.parse(timestamp))
                      : 'Unknown time',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                SizedBox(width: 3.w),
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
                SizedBox(width: 1.w),
                Text(
                  ipAddress,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
            if (affectedRecords.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(
                'Affected Records: ${affectedRecords.length}',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
