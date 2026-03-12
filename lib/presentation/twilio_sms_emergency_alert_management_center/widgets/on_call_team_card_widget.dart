import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class OnCallTeamCardWidget extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback onRefresh;

  const OnCallTeamCardWidget({
    super.key,
    required this.schedule,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final teamName = schedule['team_name'] ?? 'Unknown Team';
    final onCallUntil = schedule['on_call_until'] != null
        ? DateTime.parse(schedule['on_call_until'])
        : null;
    final currentUser = schedule['user_profiles'];
    final phone = schedule['current_on_call_phone'];

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header
            Row(
              children: [
                _buildTeamIcon(teamName),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      if (onCallUntil != null)
                        Text(
                          'On-call until ${DateFormat('MMM dd, HH:mm').format(onCallUntil)}',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge('Available'),
              ],
            ),
            SizedBox(height: 2.h),
            Divider(),
            SizedBox(height: 2.h),
            // Primary On-Call Analyst
            Row(
              children: [
                CircleAvatar(
                  radius: 8.w,
                  backgroundImage: currentUser?['avatar_url'] != null
                      ? NetworkImage(currentUser['avatar_url'])
                      : null,
                  child: currentUser?['avatar_url'] == null
                      ? Icon(Icons.person, size: 8.w)
                      : null,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary On-Call',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      Text(
                        currentUser?['full_name'] ?? 'Unknown',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      if (phone != null)
                        Text(
                          phone,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.phone, color: Colors.green, size: 6.w),
                      onPressed: phone != null
                          ? () => _makePhoneCall(phone)
                          : null,
                      tooltip: 'Call',
                    ),
                    IconButton(
                      icon: Icon(Icons.message, color: Colors.blue, size: 6.w),
                      onPressed: phone != null ? () => _sendSMS(phone) : null,
                      tooltip: 'Message',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamIcon(String teamName) {
    IconData icon;
    Color color;

    if (teamName.toLowerCase().contains('security')) {
      icon = Icons.security;
      color = Colors.red;
    } else if (teamName.toLowerCase().contains('devops')) {
      icon = Icons.settings;
      color = Colors.blue;
    } else if (teamName.toLowerCase().contains('sre')) {
      icon = Icons.engineering;
      color = Colors.orange;
    } else if (teamName.toLowerCase().contains('support')) {
      icon = Icons.support_agent;
      color = Colors.green;
    } else {
      icon = Icons.group;
      color = Colors.purple;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(icon, size: 6.w, color: color),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2.w,
            height: 2.w,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 1.w),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final uri = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
