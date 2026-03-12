import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

/// Custom Event Stream Panel - Real-time event stream showing AI interactions
class CustomEventStreamPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recentEvents;
  final VoidCallback? onRefresh;

  const CustomEventStreamPanelWidget({
    super.key,
    required this.recentEvents,
    this.onRefresh,
  });

  static const Map<String, Color> _eventColors = {
    'ai_consensus_used': Colors.blue,
    'quest_completed': Colors.green,
    'vp_earned': Colors.amber,
    'ai_quest_generation': Colors.purple,
    'ai_content_moderation': Colors.orange,
  };

  static const Map<String, IconData> _eventIcons = {
    'ai_consensus_used': Icons.psychology,
    'quest_completed': Icons.check_circle,
    'vp_earned': Icons.monetization_on,
    'ai_quest_generation': Icons.auto_awesome,
    'ai_content_moderation': Icons.shield,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Event Stream',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Real-time AI feature interactions with parameter tracking',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: Colors.green.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 2.w,
                      height: 2.w,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'LIVE',
                      style: GoogleFonts.inter(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: recentEvents.length,
            itemBuilder: (context, index) =>
                _buildEventCard(recentEvents[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventName = event['event_name'] as String? ?? 'unknown';
    final params = event['event_params'] as Map<String, dynamic>? ?? {};
    final createdAt = event['created_at'] as String? ?? '';
    final color = _eventColors[eventName] ?? Colors.grey;
    final icon = _eventIcons[eventName] ?? Icons.event;

    DateTime? time;
    try {
      time = DateTime.parse(createdAt);
    } catch (_) {}
    final timeStr = time != null ? _formatTime(time) : '';

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 4.w),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        eventName,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 8.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.3.h),
                Wrap(
                  spacing: 1.w,
                  runSpacing: 0.3.h,
                  children: params.entries
                      .take(3)
                      .map(
                        (e) =>
                            _buildParamChip(e.key, e.value.toString(), color),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamChip(String key, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        '$key: $value',
        style: GoogleFonts.inter(
          fontSize: 7.sp,
          color: AppTheme.textSecondaryLight,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
