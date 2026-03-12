import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/abstention_service.dart';
import '../../../theme/app_theme.dart';

/// Widget displaying improvement recommendations for high abstention elections
class ImprovementRecommendationsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> highAbstentionElections;

  const ImprovementRecommendationsWidget({
    super.key,
    required this.highAbstentionElections,
  });

  @override
  State<ImprovementRecommendationsWidget> createState() =>
      _ImprovementRecommendationsWidgetState();
}

class _ImprovementRecommendationsWidgetState
    extends State<ImprovementRecommendationsWidget> {
  final AbstentionService _abstentionService = AbstentionService.instance;
  Map<String, List<String>> _recommendations = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (widget.highAbstentionElections.isEmpty) return;

    setState(() => _isLoading = true);

    final recommendations = <String, List<String>>{};

    for (final item in widget.highAbstentionElections.take(3)) {
      final electionId = item['election_id'];
      final recs = await _abstentionService.getImprovementRecommendations(
        electionId,
      );
      if (recs.isNotEmpty) {
        recommendations[electionId] = recs;
      }
    }

    setState(() {
      _recommendations = recommendations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.highAbstentionElections.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 60.0,
              color: Colors.green.shade300,
            ),
            SizedBox(height: 2.h),
            Text(
              'No High Abstention Elections',
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'All elections have healthy engagement rates',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryLight),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Actions',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ...widget.highAbstentionElections.take(3).map((item) {
          final election = item['election'] as Map<String, dynamic>?;
          final electionId = item['election_id'];
          final recommendations = _recommendations[electionId] ?? [];

          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.orange.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  election?['title'] ?? 'Unknown Election',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.5.h),
                if (recommendations.isEmpty)
                  Text(
                    'Loading recommendations...',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  )
                else
                  ...recommendations.map(
                    (rec) => Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18.0,
                            color: Colors.green,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              rec,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: AppTheme.textPrimaryLight,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        SizedBox(height: 2.h),
        // General recommendations
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.blue.shade700),
                  SizedBox(width: 2.w),
                  Text(
                    'General Best Practices',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              _buildBestPractice(
                'Provide clear, concise candidate information',
              ),
              _buildBestPractice(
                'Explain the impact and importance of the election',
              ),
              _buildBestPractice(
                'Send reminder notifications before voting closes',
              ),
              _buildBestPractice('Consider adding "None of the above" option'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBestPractice(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
