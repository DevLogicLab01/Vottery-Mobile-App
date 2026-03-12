import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class SessionVideoReplayWidget extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final String? selectedSessionId;
  final Function(String) onSessionSelected;

  const SessionVideoReplayWidget({
    super.key,
    required this.sessions,
    this.selectedSessionId,
    required this.onSessionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle,
                color: const Color(0xFF6366F1),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Session Video Replay',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (selectedSessionId != null)
            _buildVideoPlayer()
          else
            _buildSessionList(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final session = sessions.firstWhere(
      (s) => s['session_id'] == selectedSessionId,
      orElse: () => {},
    );

    return Column(
      children: [
        Container(
          height: 30.h,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 40.sp,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Session Replay Player',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'User: ${session['user_id']} | ${session['screen_name']}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        _buildTimeline(session),
      ],
    );
  }

  Widget _buildTimeline(Map<String, dynamic> session) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Navigation Timeline',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildTimelineNode('0:00', 'Landing', true),
              Expanded(child: Divider(color: Colors.grey[400])),
              _buildTimelineNode('1:23', 'Browse', false),
              Expanded(child: Divider(color: Colors.grey[400])),
              _buildTimelineNode('3:45', 'Vote', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(String time, String action, bool isActive) {
    return Column(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(Icons.check, color: Colors.white, size: 12.sp),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          time,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF6366F1) : Colors.grey[600],
          ),
        ),
        Text(
          action,
          style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSessionList() {
    return Column(
      children: sessions.take(5).map((session) {
        final hasErrors = (session['errors'] as int) > 0;
        return GestureDetector(
          onTap: () => onSessionSelected(session['session_id'] as String),
          child: Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: hasErrors ? Colors.red[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: hasErrors ? Colors.red[200]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: hasErrors ? Colors.red[100] : Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasErrors ? Icons.error_outline : Icons.person,
                    color: hasErrors ? Colors.red[700] : Colors.blue[700],
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session['user_id'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${session['screen_name']} • ${session['duration']}',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        timeago.format(session['timestamp'] as DateTime),
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasErrors)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      '${session['errors']} errors',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
