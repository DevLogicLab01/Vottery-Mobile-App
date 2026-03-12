import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserFeedbackWidget extends StatelessWidget {
  final List<Map<String, dynamic>> feedback;

  const UserFeedbackWidget({super.key, required this.feedback});

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
              Icon(Icons.feedback, color: const Color(0xFF3B82F6), size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'User Feedback',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...feedback.map((item) => _buildFeedbackCard(item)),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> item) {
    final type = item['type'] as String;
    final config = _getFeedbackConfig(type);
    final rating = item['rating'] as int;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: config['color']!.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  config['icon'],
                  color: config['color'],
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 3.w),
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
                            color: config['color']!.withAlpha(51),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            config['label'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: config['color'],
                            ),
                          ),
                        ),
                        const Spacer(),
                        _buildRatingStars(rating),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'User: ${item['user_id']}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            item['message'] as String,
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[800]),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.link, color: Colors.grey[500], size: 12.sp),
              SizedBox(width: 1.w),
              Text(
                'Session: ${item['session_id']}',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey[500],
                ),
              ),
              const Spacer(),
              Text(
                timeago.format(item['timestamp'] as DateTime),
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber[700],
          size: 12.sp,
        ),
      ),
    );
  }

  Map<String, dynamic> _getFeedbackConfig(String type) {
    switch (type) {
      case 'bug_report':
        return {
          'label': 'Bug Report',
          'icon': Icons.bug_report,
          'color': const Color(0xFFEF4444),
        };
      case 'feature_request':
        return {
          'label': 'Feature Request',
          'icon': Icons.lightbulb,
          'color': const Color(0xFFF59E0B),
        };
      default:
        return {
          'label': 'General Feedback',
          'icon': Icons.comment,
          'color': const Color(0xFF3B82F6),
        };
    }
  }
}
