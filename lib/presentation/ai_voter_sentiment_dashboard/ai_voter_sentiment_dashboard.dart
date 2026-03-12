import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/voter_sentiment_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// AI Voter Sentiment Analysis Dashboard
class AiVoterSentimentDashboard extends StatefulWidget {
  const AiVoterSentimentDashboard({super.key});

  @override
  State<AiVoterSentimentDashboard> createState() =>
      _AiVoterSentimentDashboardState();
}

class _AiVoterSentimentDashboardState extends State<AiVoterSentimentDashboard> {
  final VoterSentimentService _sentimentService =
      VoterSentimentService.instance;
  bool _isLoading = true;
  String? _selectedElectionId;
  Map<String, dynamic> _sentimentAnalysis = {};
  List<Map<String, dynamic>> _sentimentTrends = [];
  Map<String, dynamic> _sentimentThemes = {};

  @override
  void initState() {
    super.initState();
    _loadSentimentData();
  }

  Future<void> _loadSentimentData() async {
    setState(() => _isLoading = true);

    try {
      if (_selectedElectionId != null) {
        final results = await Future.wait([
          _sentimentService.analyzeElectionSentiment(
            electionId: _selectedElectionId!,
          ),
          _sentimentService.getSentimentTrends(
            electionId: _selectedElectionId!,
            days: 30,
          ),
          _sentimentService.getSentimentThemes(
            electionId: _selectedElectionId!,
          ),
        ]);

        setState(() {
          _sentimentAnalysis = results[0] as Map<String, dynamic>;
          _sentimentTrends = results[1] as List<Map<String, dynamic>>;
          _sentimentThemes = results[2] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Load sentiment data error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AiVoterSentimentDashboard',
      onRetry: _loadSentimentData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'AI Voter Sentiment',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: 6.w),
              onPressed: _loadSentimentData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _selectedElectionId == null
            ? NoDataEmptyState(
                title: 'Select Election',
                description:
                    'Choose an election to analyze voter sentiment trends.',
                onRefresh: _loadSentimentData,
              )
            : RefreshIndicator(
                onRefresh: _loadSentimentData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSentimentOverview(),
                      SizedBox(height: 3.h),
                      _buildSentimentBreakdown(),
                      SizedBox(height: 3.h),
                      _buildSentimentThemes(),
                      SizedBox(height: 3.h),
                      _buildKeyInsights(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSentimentOverview() {
    final overallSentiment =
        _sentimentAnalysis['overall_sentiment'] ?? 'neutral';
    final sentimentScore = _sentimentAnalysis['sentiment_score'] ?? 50;
    final engagementQuality =
        _sentimentAnalysis['engagement_quality'] ?? 'medium';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sentiment Overview',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSentimentIndicator(
                  overallSentiment,
                  _getSentimentColor(overallSentiment),
                  _getSentimentIcon(overallSentiment),
                ),
                Column(
                  children: [
                    Text(
                      '$sentimentScore',
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    Text(
                      'Sentiment Score',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(
                      _getEngagementIcon(engagementQuality),
                      size: 8.w,
                      color: _getEngagementColor(engagementQuality),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      engagementQuality.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: _getEngagementColor(engagementQuality),
                      ),
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

  Widget _buildSentimentIndicator(
    String sentiment,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 8.w, color: color),
        ),
        SizedBox(height: 1.h),
        Text(
          sentiment.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSentimentBreakdown() {
    final positivePercentage = _sentimentAnalysis['positive_percentage'] ?? 0;
    final neutralPercentage = _sentimentAnalysis['neutral_percentage'] ?? 0;
    final negativePercentage = _sentimentAnalysis['negative_percentage'] ?? 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sentiment Breakdown',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            _buildPercentageBar('Positive', positivePercentage, Colors.green),
            SizedBox(height: 1.h),
            _buildPercentageBar('Neutral', neutralPercentage, Colors.grey),
            SizedBox(height: 1.h),
            _buildPercentageBar('Negative', negativePercentage, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageBar(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withAlpha(51),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 1.h,
        ),
      ],
    );
  }

  Widget _buildSentimentThemes() {
    final positiveThemes = _sentimentThemes['positive_themes'] ?? [];
    final negativeThemes = _sentimentThemes['negative_themes'] ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sentiment Themes',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            if (positiveThemes.isNotEmpty) ...[
              Text(
                'Positive Themes',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: positiveThemes
                    .map<Widget>(
                      (theme) => _buildThemeChip(theme, Colors.green),
                    )
                    .toList(),
              ),
              SizedBox(height: 2.h),
            ],
            if (negativeThemes.isNotEmpty) ...[
              Text(
                'Negative Themes',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: negativeThemes
                    .map<Widget>((theme) => _buildThemeChip(theme, Colors.red))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(String theme, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        theme,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildKeyInsights() {
    final insights = _sentimentAnalysis['key_insights'] ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Insights',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            ...insights
                .map<Widget>(
                  (insight) => Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 4.w,
                          color: AppTheme.vibrantYellow,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            insight,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Icons.sentiment_very_satisfied;
      case 'negative':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getEngagementColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'low':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getEngagementIcon(String quality) {
    switch (quality.toLowerCase()) {
      case 'high':
        return Icons.trending_up;
      case 'low':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }
}
