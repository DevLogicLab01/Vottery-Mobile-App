import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class OptimizationSuggestionsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;

  const OptimizationSuggestionsWidget({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-powered header
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, color: Colors.white, size: 6.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Optimization',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Powered by Claude AI',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Suggestions list
          Text(
            'Personalized Recommendations',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...suggestions.map((suggestion) {
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: _buildSuggestionCard(
                context,
                suggestion['suggestion'] as String,
                suggestion['impact'] as String,
                suggestion['action'] as String,
              ),
            );
          }),

          if (suggestions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 15.w,
                      color: Colors.green,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'You\'re doing great!',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppTheme.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'No optimization suggestions at this time',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    String suggestion,
    String impact,
    String action,
  ) {
    final impactColor = impact == 'high'
        ? Colors.red
        : impact == 'medium'
        ? Colors.orange
        : Colors.blue;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: impactColor.withAlpha(77), width: 2),
        boxShadow: [
          BoxShadow(
            color: impactColor.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: impactColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${impact.toUpperCase()} IMPACT',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: impactColor,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.auto_awesome, color: impactColor, size: 5.w),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            suggestion,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleAction(context, action),
              style: ElevatedButton.styleFrom(
                backgroundColor: impactColor,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                _getActionLabel(action),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'create_jolt':
        return 'Create Jolt';
      case 'join_prediction':
        return 'Join Prediction Pool';
      case 'view_quests':
        return 'View Quests';
      case 'browse_elections':
        return 'Browse Elections';
      default:
        return 'Take Action';
    }
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'create_jolt':
        Navigator.pushNamed(context, '/jolts-video-feed');
        break;
      case 'join_prediction':
        Navigator.pushNamed(context, '/social-home-feed');
        break;
      case 'view_quests':
        Navigator.pushNamed(context, '/feed-quest-dashboard');
        break;
      case 'browse_elections':
        Navigator.pushNamed(context, '/vote-discovery');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action: $action'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }
}
