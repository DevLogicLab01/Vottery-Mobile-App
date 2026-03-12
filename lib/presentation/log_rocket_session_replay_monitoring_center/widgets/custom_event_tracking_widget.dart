import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class CustomEventTrackingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> events;

  const CustomEventTrackingWidget({super.key, required this.events});

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
                Icons.track_changes,
                color: const Color(0xFF8B5CF6),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Custom Event Tracking',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...events.map((event) => _buildEventCard(event)),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventName = event['event_name'] as String;
    final eventConfig = _getEventConfig(eventName);

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [eventConfig['color']!.withAlpha(26), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: eventConfig['color']!.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: eventConfig['color']!.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Icon(
              eventConfig['icon'],
              color: eventConfig['color'],
              size: 16.sp,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventConfig['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'User: ${event['user_id']}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  timeago.format(event['timestamp'] as DateTime),
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (event['metadata'] != null)
            _buildMetadataBadge(event['metadata'] as Map<String, dynamic>),
        ],
      ),
    );
  }

  Widget _buildMetadataBadge(Map<String, dynamic> metadata) {
    final amount = metadata['amount'];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        amount != null ? '\$$amount' : 'Details',
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: Colors.green[700],
        ),
      ),
    );
  }

  Map<String, dynamic> _getEventConfig(String eventName) {
    switch (eventName) {
      case 'vote_cast':
        return {
          'label': 'Vote Cast',
          'icon': Icons.how_to_vote,
          'color': const Color(0xFF6366F1),
        };
      case 'payment_completed':
        return {
          'label': 'Payment Completed',
          'icon': Icons.payment,
          'color': const Color(0xFF10B981),
        };
      case 'prize_distributed':
        return {
          'label': 'Prize Distributed',
          'icon': Icons.card_giftcard,
          'color': const Color(0xFFF59E0B),
        };
      case 'election_created':
        return {
          'label': 'Election Created',
          'icon': Icons.create,
          'color': const Color(0xFF8B5CF6),
        };
      default:
        return {
          'label': 'Custom Event',
          'icon': Icons.event,
          'color': Colors.grey[600]!,
        };
    }
  }
}
