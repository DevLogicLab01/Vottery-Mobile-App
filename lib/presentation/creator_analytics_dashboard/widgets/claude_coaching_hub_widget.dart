import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/anthropic_service.dart';
import '../../../theme/app_theme.dart';

class ClaudeCoachingHubWidget extends StatefulWidget {
  final Map<String, dynamic> earnings;
  final Map<String, dynamic> revenueBreakdown;
  final Map<String, dynamic> creatorTier;

  const ClaudeCoachingHubWidget({
    super.key,
    required this.earnings,
    required this.revenueBreakdown,
    required this.creatorTier,
  });

  @override
  State<ClaudeCoachingHubWidget> createState() =>
      _ClaudeCoachingHubWidgetState();
}

class _ClaudeCoachingHubWidgetState extends State<ClaudeCoachingHubWidget> {
  final AnthropicService _anthropicService = AnthropicService.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _recommendations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoachingRecommendations();
  }

  Future<void> _loadCoachingRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prompt = _buildCoachingPrompt();
      final response = await AnthropicService.analyzeRevenueRisk();

      final recommendations = _parseRecommendations(response.toString());

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load coaching recommendations error: $e');
      setState(() {
        _error = 'Unable to load AI coaching recommendations';
        _isLoading = false;
        _recommendations = _getDefaultRecommendations();
      });
    }
  }

  String _buildCoachingPrompt() {
    final totalEarnings = widget.earnings['total_earnings'] ?? 0.0;
    final thisMonth = widget.earnings['this_month'] ?? 0.0;
    final tierName = widget.creatorTier['tier_name'] ?? 'Starter';
    final vpMultiplier = widget.creatorTier['vp_multiplier'] ?? 1.0;

    return '''
You are an expert creator economy coach analyzing a content creator's performance.

Creator Profile:
- Current Tier: $tierName (VP Multiplier: ${vpMultiplier}x)
- Total Lifetime Earnings: \$${totalEarnings.toStringAsFixed(2)}
- This Month Earnings: \$${thisMonth.toStringAsFixed(2)}
- Revenue Breakdown: ${widget.revenueBreakdown}

Provide 5 specific, actionable recommendations to optimize earnings. Format each as:
[PRIORITY: HIGH/MEDIUM/LOW] Title: Brief description (1-2 sentences)

Focus on:
1. Content strategy improvements
2. Engagement optimization
3. Monetization opportunities
4. Tier progression strategies
5. Audience growth tactics

Be specific, data-driven, and actionable.''';
  }

  List<Map<String, dynamic>> _parseRecommendations(String response) {
    final recommendations = <Map<String, dynamic>>[];
    final lines = response.split('\n');

    for (final line in lines) {
      if (line.contains('[PRIORITY:')) {
        final priorityMatch = RegExp(
          r'\[PRIORITY: (HIGH|MEDIUM|LOW)\]',
        ).firstMatch(line);
        final titleMatch = RegExp(r'\] (.+?):').firstMatch(line);
        final descriptionMatch = RegExp(r': (.+)').firstMatch(line);

        if (priorityMatch != null &&
            titleMatch != null &&
            descriptionMatch != null) {
          recommendations.add({
            'priority': priorityMatch.group(1)!,
            'title': titleMatch.group(1)!.trim(),
            'description': descriptionMatch.group(1)!.trim(),
            'category': _categorizeRecommendation(titleMatch.group(1)!),
          });
        }
      }
    }

    return recommendations.isEmpty
        ? _getDefaultRecommendations()
        : recommendations;
  }

  String _categorizeRecommendation(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('content') || lowerTitle.contains('video')) {
      return 'Content Strategy';
    } else if (lowerTitle.contains('engagement') ||
        lowerTitle.contains('audience')) {
      return 'Engagement';
    } else if (lowerTitle.contains('monetization') ||
        lowerTitle.contains('revenue')) {
      return 'Monetization';
    } else if (lowerTitle.contains('tier') ||
        lowerTitle.contains('progression')) {
      return 'Tier Growth';
    } else {
      return 'General';
    }
  }

  List<Map<String, dynamic>> _getDefaultRecommendations() {
    return [
      {
        'priority': 'HIGH',
        'title': 'Increase Content Frequency',
        'description':
            'Post 3-5 elections per week to maximize visibility and engagement.',
        'category': 'Content Strategy',
      },
      {
        'priority': 'HIGH',
        'title': 'Optimize Video Length',
        'description':
            'Keep videos between 60-90 seconds for highest completion rates.',
        'category': 'Content Strategy',
      },
      {
        'priority': 'MEDIUM',
        'title': 'Engage with Comments',
        'description':
            'Respond to comments within 2 hours to boost engagement metrics.',
        'category': 'Engagement',
      },
      {
        'priority': 'MEDIUM',
        'title': 'Leverage Brand Partnerships',
        'description':
            'Apply for 2-3 brand campaigns monthly to diversify revenue streams.',
        'category': 'Monetization',
      },
      {
        'priority': 'LOW',
        'title': 'Focus on Tier Progression',
        'description':
            'Reach next tier milestone to unlock higher VP multipliers.',
        'category': 'Tier Growth',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.vibrantYellow.withAlpha(26),
            Colors.purple.withAlpha(26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppTheme.vibrantYellow.withAlpha(77),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.vibrantYellow,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(Icons.psychology, color: Colors.white, size: 6.w),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Claude AI Coaching Hub',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Personalized earning optimization',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 5.w,
                  height: 5.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.vibrantYellow,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: AppTheme.vibrantYellow,
                    size: 6.w,
                  ),
                  onPressed: _loadCoachingRecommendations,
                ),
            ],
          ),
          if (_error != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 5.w),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 2.h),
          ..._recommendations.map(
            (rec) => _buildRecommendationCard(rec, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    Map<String, dynamic> recommendation,
    ThemeData theme,
  ) {
    final priority = recommendation['priority'] as String;
    final title = recommendation['title'] as String;
    final description = recommendation['description'] as String;
    final category = recommendation['category'] as String;

    Color priorityColor;
    IconData priorityIcon;

    switch (priority) {
      case 'HIGH':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'MEDIUM':
        priorityColor = Colors.orange;
        priorityIcon = Icons.warning_amber;
        break;
      case 'LOW':
      default:
        priorityColor = Colors.blue;
        priorityIcon = Icons.info_outline;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withAlpha(26),
            blurRadius: 4,
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
                  color: priorityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    Icon(priorityIcon, color: priorityColor, size: 4.w),
                    SizedBox(width: 1.w),
                    Text(
                      priority,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: priorityColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.vibrantYellow.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.vibrantYellow,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
