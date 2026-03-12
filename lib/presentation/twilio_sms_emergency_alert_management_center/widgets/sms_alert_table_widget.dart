import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SmsAlertTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;
  final VoidCallback onRefresh;

  const SmsAlertTableWidget({
    super.key,
    required this.alerts,
    required this.onRefresh,
  });

  @override
  State<SmsAlertTableWidget> createState() => _SmsAlertTableWidgetState();
}

class _SmsAlertTableWidgetState extends State<SmsAlertTableWidget> {
  String _searchQuery = '';
  String _filterType = 'all';
  String _filterSeverity = 'all';
  String _filterStatus = 'all';

  List<Map<String, dynamic>> get _filteredAlerts {
    return widget.alerts.where((alert) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          alert['message'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          alert['recipient_phone'].toString().contains(_searchQuery);

      final matchesType =
          _filterType == 'all' || alert['alert_type'] == _filterType;
      final matchesSeverity =
          _filterSeverity == 'all' || alert['severity'] == _filterSeverity;
      final matchesStatus =
          _filterStatus == 'all' || alert['delivery_status'] == _filterStatus;

      return matchesSearch && matchesType && matchesSeverity && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filters
        Container(
          padding: EdgeInsets.all(4.w),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search alerts...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  prefixIcon: Icon(Icons.search, size: 5.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: AppTheme.borderLight),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              SizedBox(height: 2.h),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'Type',
                      _filterType,
                      ['all', 'fraud', 'failover', 'security', 'performance'],
                      (value) => setState(() => _filterType = value),
                    ),
                    SizedBox(width: 2.w),
                    _buildFilterChip(
                      'Severity',
                      _filterSeverity,
                      ['all', 'critical', 'high', 'medium', 'low'],
                      (value) => setState(() => _filterSeverity = value),
                    ),
                    SizedBox(width: 2.w),
                    _buildFilterChip(
                      'Status',
                      _filterStatus,
                      ['all', 'delivered', 'pending', 'failed'],
                      (value) => setState(() => _filterStatus = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Alert List
        Expanded(
          child: _filteredAlerts.isEmpty
              ? Center(
                  child: Text(
                    'No alerts found',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = _filteredAlerts[index];
                    return _buildAlertCard(alert);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => options
          .map(
            (option) =>
                PopupMenuItem(value: option, child: Text(option.toUpperCase())),
          )
          .toList(),
      child: Chip(
        label: Text(
          '$label: ${currentValue.toUpperCase()}',
          style: GoogleFonts.inter(fontSize: 12.sp),
        ),
        avatar: Icon(Icons.filter_list, size: 4.w),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final sentAt = DateTime.parse(alert['sent_at']);
    final acknowledgedAt = alert['acknowledged_at'] != null
        ? DateTime.parse(alert['acknowledged_at'])
        : null;
    final responseTime = alert['response_time_minutes'];

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildSeverityBadge(alert['severity']),
                    SizedBox(width: 2.w),
                    _buildTypeBadge(alert['alert_type']),
                  ],
                ),
                Text(
                  DateFormat('MMM dd, HH:mm').format(sentAt),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            // Message Preview
            Text(
              alert['message'],
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppTheme.textPrimaryLight,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Divider(),
            SizedBox(height: 1.h),
            // Details Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipient',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      alert['recipient_phone'],
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Delivery',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    _buildStatusBadge(alert['delivery_status']),
                  ],
                ),
              ],
            ),
            if (acknowledgedAt != null) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 4.w, color: Colors.green),
                  SizedBox(width: 1.w),
                  Text(
                    'Acknowledged',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  if (responseTime != null)
                    Text(
                      'Response: ${responseTime}m',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
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

  Widget _buildSeverityBadge(String severity) {
    Color color;
    switch (severity) {
      case 'critical':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.yellow.shade700;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color),
      ),
      child: Text(
        severity.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'fraud':
        icon = Icons.security;
        color = Colors.red;
        break;
      case 'failover':
        icon = Icons.autorenew;
        color = Colors.orange;
        break;
      case 'security':
        icon = Icons.shield;
        color = Colors.purple;
        break;
      case 'performance':
        icon = Icons.speed;
        color = Colors.blue;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 3.w, color: color),
          SizedBox(width: 1.w),
          Text(
            type.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'delivered':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 3.w, color: color),
        SizedBox(width: 1.w),
        Text(
          status.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
