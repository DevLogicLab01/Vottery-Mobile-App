import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../services/mcq_service.dart';
import '../../../theme/app_theme.dart';

class ResponseAnalyticsWidget extends StatefulWidget {
  final String electionId;

  const ResponseAnalyticsWidget({super.key, required this.electionId});

  @override
  State<ResponseAnalyticsWidget> createState() =>
      _ResponseAnalyticsWidgetState();
}

class _ResponseAnalyticsWidgetState extends State<ResponseAnalyticsWidget> {
  final MCQService _mcqService = MCQService.instance;
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final analytics = await _mcqService.getMCQAnalytics(widget.electionId);

    setState(() {
      _analytics = analytics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analytics.isEmpty) {
      return Center(
        child: Text(
          'No analytics data available',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 12.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _analytics.length,
      itemBuilder: (context, index) {
        final questionId = _analytics.keys.elementAt(index);
        final data = _analytics[questionId];
        return _buildAnalyticsCard(data);
      },
    );
  }

  Widget _buildAnalyticsCard(Map<String, dynamic> data) {
    final totalResponses = data['total_responses'] ?? 0;
    final correctResponses = data['correct_responses'] ?? 0;
    final accuracyRate = data['accuracy_rate'] ?? '0.0';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['question_text'] ?? '',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                _buildMetric(
                  'Responses',
                  totalResponses.toString(),
                  Icons.people,
                ),
                SizedBox(width: 4.w),
                _buildMetric(
                  'Correct',
                  correctResponses.toString(),
                  Icons.check_circle,
                ),
                SizedBox(width: 4.w),
                _buildMetric('Accuracy', '$accuracyRate%', Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Icon(icon, size: 5.w, color: AppTheme.primaryLight),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
            ),
            Text(
              label,
              style: google_fonts.GoogleFonts.inter(
                fontSize: 9.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
