import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/claude_service.dart';
import '../../../theme/app_theme.dart';

/// AI Optimization Recommendations Widget with Claude-powered insights
class AiOptimizationRecommendationsWidget extends StatefulWidget {
  final String campaignId;
  final Map<String, dynamic> campaignData;

  const AiOptimizationRecommendationsWidget({
    super.key,
    required this.campaignId,
    required this.campaignData,
  });

  @override
  State<AiOptimizationRecommendationsWidget> createState() =>
      _AiOptimizationRecommendationsWidgetState();
}

class _AiOptimizationRecommendationsWidgetState
    extends State<AiOptimizationRecommendationsWidget> {
  final ClaudeService _claudeService = ClaudeService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      final recommendations = await _claudeService.getContextualRecommendations(
        screenContext: 'advertiser_roi_dashboard',
        userData: {
          'campaign_id': widget.campaignId,
          'campaign_data': widget.campaignData,
        },
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load AI recommendations error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 5.w,
                  color: AppTheme.vibrantYellow,
                ),
                SizedBox(width: 2.w),
                Text(
                  'AI Optimization Recommendations',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.vibrantYellow,
                    ),
                  )
                : _recommendations.isEmpty
                ? Text(
                    'No recommendations available',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  )
                : Column(
                    children: _recommendations
                        .map((rec) => _buildRecommendationCard(rec))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final title = recommendation['title'] ?? 'Recommendation';
    final description = recommendation['description'] ?? '';
    final expectedImpact = recommendation['expected_impact'] ?? 'Unknown';
    final priority = recommendation['priority'] ?? 'medium';
    final category = recommendation['category'] ?? 'general';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority).withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: _getPriorityColor(priority).withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.trending_up, size: 4.w, color: Colors.green),
              SizedBox(width: 1.w),
              Text(
                'Expected Impact: $expectedImpact',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 4.w,
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 1.w),
              Text(
                category.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'campaign':
        return Icons.campaign;
      case 'engagement':
        return Icons.people;
      case 'revenue':
        return Icons.attach_money;
      case 'performance':
        return Icons.speed;
      default:
        return Icons.lightbulb;
    }
  }
}
