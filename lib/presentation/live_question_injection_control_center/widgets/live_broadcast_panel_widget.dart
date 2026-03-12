import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../services/mcq_service.dart';
import '../../../theme/app_theme.dart';

class LiveBroadcastPanelWidget extends StatefulWidget {
  final String electionId;
  final int activeVotersCount;

  const LiveBroadcastPanelWidget({
    super.key,
    required this.electionId,
    required this.activeVotersCount,
  });

  @override
  State<LiveBroadcastPanelWidget> createState() =>
      _LiveBroadcastPanelWidgetState();
}

class _LiveBroadcastPanelWidgetState extends State<LiveBroadcastPanelWidget> {
  final MCQService _mcqService = MCQService.instance;
  List<Map<String, dynamic>> _liveQuestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupRealTimeSubscription();
  }

  void _setupRealTimeSubscription() {
    _mcqService.streamLiveQuestions(widget.electionId).listen((questions) {
      if (mounted) {
        setState(() {
          _liveQuestions = questions;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRealTimeStatus(),
          SizedBox(height: 2.h),
          Text(
            'Live Questions (${_liveQuestions.length})',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_liveQuestions.isEmpty)
            Center(
              child: Text(
                'No live questions yet',
                style: google_fonts.GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            )
          else
            ..._liveQuestions.map(
              (question) => _buildLiveQuestionCard(question),
            ),
        ],
      ),
    );
  }

  Widget _buildRealTimeStatus() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.accentLight, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 2.w,
                height: 2.w,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-Time Broadcast Active',
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentLight,
                  ),
                ),
                Text(
                  'Connected to ${widget.activeVotersCount} active voters',
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.wifi, color: AppTheme.accentLight, size: 6.w),
        ],
      ),
    );
  }

  Widget _buildLiveQuestionCard(Map<String, dynamic> question) {
    final isLiveInjected = question['is_live_injected'] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isLiveInjected)
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
                      children: [
                        Icon(Icons.bolt, size: 3.w, color: Colors.green),
                        SizedBox(width: 1.w),
                        Text(
                          'LIVE INJECTED',
                          style: google_fonts.GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(
                  'Q${question['question_order']}',
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              question['question_text'] ?? '',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textPrimaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
