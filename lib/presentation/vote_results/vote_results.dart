import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/demographic_filter_widget.dart';
import './widgets/result_bar_chart_widget.dart';
import './widgets/statistics_card_widget.dart';
import './widgets/timeline_graph_widget.dart';

class VoteResults extends StatefulWidget {
  const VoteResults({super.key});

  @override
  State<VoteResults> createState() => _VoteResultsState();
}

class _VoteResultsState extends State<VoteResults> {
  bool _showDemographics = false;
  String _selectedTimePeriod = 'All Time';
  bool _isRefreshing = false;

  // Mock vote data
  final Map<String, dynamic> _voteData = {
    "voteId": "vote_2026_001",
    "title": "Community Park Renovation Project",
    "totalParticipants": 1247,
    "status": "active",
    "createdBy": "City Council",
    "lastSyncTime": DateTime.now().subtract(const Duration(minutes: 2)),
    "options": [
      {
        "id": "opt_1",
        "title": "Modern Playground Equipment",
        "votes": 487,
        "percentage": 39.1,
        "color": 0xFF3B82F6,
        "trending": true,
        "demographics": {
          "age_18_30": 145,
          "age_31_45": 198,
          "age_46_60": 102,
          "age_60_plus": 42,
        },
      },
      {
        "id": "opt_2",
        "title": "Community Garden Expansion",
        "votes": 356,
        "percentage": 28.5,
        "color": 0xFF10B981,
        "trending": false,
        "demographics": {
          "age_18_30": 78,
          "age_31_45": 134,
          "age_46_60": 98,
          "age_60_plus": 46,
        },
      },
      {
        "id": "opt_3",
        "title": "Sports Court Upgrade",
        "votes": 289,
        "percentage": 23.2,
        "color": 0xFFF59E0B,
        "trending": false,
        "demographics": {
          "age_18_30": 112,
          "age_31_45": 89,
          "age_46_60": 67,
          "age_60_plus": 21,
        },
      },
      {
        "id": "opt_4",
        "title": "Walking Trail Enhancement",
        "votes": 115,
        "percentage": 9.2,
        "color": 0xFF8B5CF6,
        "trending": false,
        "demographics": {
          "age_18_30": 23,
          "age_31_45": 34,
          "age_46_60": 38,
          "age_60_plus": 20,
        },
      },
    ],
    "statistics": {
      "participationRate": 78.4,
      "averageCompletionTime": "2m 34s",
      "peakVotingHour": "6:00 PM",
      "deviceBreakdown": {"mobile": 892, "tablet": 234, "desktop": 121},
    },
    "timeline": [
      {"hour": "12 AM", "votes": 12},
      {"hour": "3 AM", "votes": 8},
      {"hour": "6 AM", "votes": 45},
      {"hour": "9 AM", "votes": 156},
      {"hour": "12 PM", "votes": 234},
      {"hour": "3 PM", "votes": 289},
      {"hour": "6 PM", "votes": 378},
      {"hour": "9 PM", "votes": 125},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'VoteResults',
      onRetry: _refreshResults,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Vote Results',
          variant: CustomAppBarVariant.withBack,
          onBackPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'share',
                color: theme.appBarTheme.foregroundColor ?? Colors.white,
                size: 24,
              ),
              onPressed: _shareResults,
              tooltip: 'Share Results',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshResults,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                SizedBox(height: 2.h),
                _buildFilterSection(theme),
                SizedBox(height: 2.h),
                _buildResultsSection(theme),
                SizedBox(height: 3.h),
                _buildTimelineSection(theme),
                SizedBox(height: 3.h),
                _buildStatisticsSection(theme),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildExportButton(theme),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _voteData["title"] as String,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'people',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                '${_voteData["totalParticipants"]} participants',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Live',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Last updated ${_getTimeAgo(_voteData["lastSyncTime"] as DateTime)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.5.h),
          DemographicFilterWidget(
            showDemographics: _showDemographics,
            selectedTimePeriod: _selectedTimePeriod,
            onDemographicsChanged: (value) {
              setState(() => _showDemographics = value);
            },
            onTimePeriodChanged: (value) {
              setState(() => _selectedTimePeriod = value ?? 'All Time');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.5.h),
          ...(_voteData["options"] as List).map((option) {
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: ResultBarChartWidget(
                option: option as Map<String, dynamic>,
                showDemographics: _showDemographics,
                onLongPress: () => _showDetailedBreakdown(option),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voting Timeline',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.5.h),
          TimelineGraphWidget(timelineData: _voteData["timeline"] as List),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(ThemeData theme) {
    final stats = _voteData["statistics"] as Map<String, dynamic>;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: StatisticsCardWidget(
                  title: 'Participation',
                  value: '${stats["participationRate"]}%',
                  icon: 'trending_up',
                  color: theme.colorScheme.tertiary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: StatisticsCardWidget(
                  title: 'Avg. Time',
                  value: stats["averageCompletionTime"] as String,
                  icon: 'timer',
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: StatisticsCardWidget(
                  title: 'Peak Hour',
                  value: stats["peakVotingHour"] as String,
                  icon: 'schedule',
                  color: const Color(0xFFF59E0B),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: StatisticsCardWidget(
                  title: 'Mobile Users',
                  value:
                      '${(((stats["deviceBreakdown"] as Map)["mobile"] as int) / (_voteData["totalParticipants"] as int) * 100).toStringAsFixed(0)}%',
                  icon: 'phone_android',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: _exportResults,
      backgroundColor: theme.colorScheme.secondary,
      foregroundColor: theme.colorScheme.onSecondary,
      icon: CustomIconWidget(
        iconName: 'download',
        color: theme.colorScheme.onSecondary,
        size: 20,
      ),
      label: Text(
        'Export Results',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _refreshResults() async {
    setState(() => _isRefreshing = true);

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
      _voteData["lastSyncTime"] = DateTime.now();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Results updated successfully'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sharing results...'),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _exportResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting results as PDF...'),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _showDetailedBreakdown(Map<String, dynamic> option) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailedBreakdownSheet(option),
    );
  }

  Widget _buildDetailedBreakdownSheet(Map<String, dynamic> option) {
    final theme = Theme.of(context);
    final demographics = option["demographics"] as Map<String, dynamic>;

    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 12.w,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option["title"] as String,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${option["votes"]} votes (${option["percentage"]}%)',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Age Demographics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                _buildDemographicRow(
                  theme,
                  '18-30',
                  demographics["age_18_30"] as int,
                  option["votes"] as int,
                ),
                SizedBox(height: 1.5.h),
                _buildDemographicRow(
                  theme,
                  '31-45',
                  demographics["age_31_45"] as int,
                  option["votes"] as int,
                ),
                SizedBox(height: 1.5.h),
                _buildDemographicRow(
                  theme,
                  '46-60',
                  demographics["age_46_60"] as int,
                  option["votes"] as int,
                ),
                SizedBox(height: 1.5.h),
                _buildDemographicRow(
                  theme,
                  '60+',
                  demographics["age_60_plus"] as int,
                  option["votes"] as int,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicRow(
    ThemeData theme,
    String ageGroup,
    int votes,
    int totalVotes,
  ) {
    final percentage = (votes / totalVotes * 100).toStringAsFixed(1);

    return Row(
      children: [
        SizedBox(
          width: 20.w,
          child: Text(
            ageGroup,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: votes / totalVotes,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 3.w),
        SizedBox(
          width: 15.w,
          child: Text(
            '$votes ($percentage%)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
