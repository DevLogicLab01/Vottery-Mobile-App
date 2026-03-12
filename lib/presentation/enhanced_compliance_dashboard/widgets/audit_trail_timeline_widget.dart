import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/compliance_service.dart';
import '../../../widgets/custom_icon_widget.dart';

class AuditTrailTimelineWidget extends StatefulWidget {
  const AuditTrailTimelineWidget({super.key});

  @override
  State<AuditTrailTimelineWidget> createState() =>
      _AuditTrailTimelineWidgetState();
}

class _AuditTrailTimelineWidgetState extends State<AuditTrailTimelineWidget> {
  final ComplianceService _complianceService = ComplianceService.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _auditLogs = [];
  String? _selectedFilter;

  final List<String> _filters = ['All', 'GDPR', 'CCPA', 'EMERGENCY'];

  @override
  void initState() {
    super.initState();
    _loadAuditTrail();
  }

  Future<void> _loadAuditTrail() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _complianceService.getComplianceAuditLogs(
        complianceType: _selectedFilter == 'All' ? null : _selectedFilter,
        limit: 50,
      );
      setState(() => _auditLogs = logs);
    } catch (e) {
      debugPrint('Load audit trail error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  children: _filters.map((filter) {
                    final isSelected =
                        _selectedFilter == filter ||
                        (_selectedFilter == null && filter == 'All');
                    return FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter == 'All' ? null : filter;
                        });
                        _loadAuditTrail();
                      },
                      selectedColor: theme.colorScheme.primary.withAlpha(51),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
              : _auditLogs.isEmpty
              ? Center(
                  child: Text(
                    'No audit trail entries',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _auditLogs.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineItem(
                      context,
                      _auditLogs[index],
                      index,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    Map<String, dynamic> log,
    int index,
  ) {
    final theme = Theme.of(context);
    final complianceType = log['compliance_type'] ?? 'UNKNOWN';
    final actionType = log['action_type'] ?? 'action';
    final color = _getComplianceColor(complianceType);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: _getActionIcon(actionType),
                  color: color,
                  size: 20,
                ),
              ),
            ),
            if (index < _auditLogs.length - 1)
              Container(width: 2, height: 60, color: theme.dividerColor),
          ],
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        complianceType,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 12, color: Colors.green),
                          SizedBox(width: 1.w),
                          Text(
                            'Verified',
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  actionType.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _formatDate(log['created_at']),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (log['details'] != null) ...[
                  SizedBox(height: 1.h),
                  Text(
                    'Details: ${log['details'].toString()}',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getComplianceColor(String type) {
    switch (type.toUpperCase()) {
      case 'GDPR':
        return Colors.blue;
      case 'CCPA':
        return Colors.purple;
      case 'EMERGENCY':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getActionIcon(String action) {
    if (action.contains('submit')) return 'send';
    if (action.contains('request')) return 'description';
    if (action.contains('emergency')) return 'emergency';
    if (action.contains('suspend')) return 'pause_circle';
    return 'check_circle';
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
