import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

/// Live result pie chart widget for ballot visualizations
class LiveResultPieChartWidget extends StatefulWidget {
  final String electionId;
  final bool showResults;
  final List<Map<String, dynamic>> options;

  const LiveResultPieChartWidget({
    super.key,
    required this.electionId,
    required this.showResults,
    required this.options,
  });

  @override
  State<LiveResultPieChartWidget> createState() =>
      _LiveResultPieChartWidgetState();
}

class _LiveResultPieChartWidgetState extends State<LiveResultPieChartWidget> {
  final SupabaseClient _client = SupabaseService.instance.client;
  RealtimeChannel? _votesChannel;

  List<Map<String, dynamic>> _voteResults = [];
  int _totalVotes = 0;
  bool _isLoading = true;
  int? _highlightedIndex;

  @override
  void initState() {
    super.initState();
    _loadVoteResults();
    _subscribeToVoteUpdates();
  }

  @override
  void dispose() {
    _votesChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadVoteResults() async {
    try {
      // Get vote counts
      final votesResponse = await _client
          .from('votes')
          .select('selected_option_id')
          .eq('election_id', widget.electionId);

      final votes = List<Map<String, dynamic>>.from(votesResponse);

      // Calculate vote counts
      final Map<String, int> voteCounts = {};
      for (var vote in votes) {
        final optionId = vote['selected_option_id'] as String?;
        if (optionId != null) {
          voteCounts[optionId] = (voteCounts[optionId] ?? 0) + 1;
        }
      }

      final totalVotes = votes.length;

      // Build results
      final results = widget.options.map((option) {
        final optionId = option['id'] as String;
        final voteCount = voteCounts[optionId] ?? 0;
        final percentage = totalVotes > 0
            ? (voteCount / totalVotes * 100)
            : 0.0;

        return {
          'id': optionId,
          'title': option['title'],
          'vote_count': voteCount,
          'percentage': percentage,
        };
      }).toList();

      // Sort by vote count
      results.sort(
        (a, b) => (b['vote_count'] as int).compareTo(a['vote_count'] as int),
      );

      if (mounted) {
        setState(() {
          _voteResults = results;
          _totalVotes = totalVotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load vote results error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToVoteUpdates() {
    _votesChannel = _client
        .channel('votes_chart:${widget.electionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'votes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'election_id',
            value: widget.electionId,
          ),
          callback: (payload) {
            _loadVoteResults();
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.showResults) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            Icon(
              Icons.lock_outline,
              size: 12.w,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'Results Hidden',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Vote totals will be visible after voting ends',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_totalVotes == 0) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 12.w,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Votes Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Be the first to vote!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Results',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.how_to_vote,
                      size: 4.w,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '$_totalVotes votes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            height: 35.h,
            child: Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sections: _voteResults.asMap().entries.map((entry) {
                        final index = entry.key;
                        final result = entry.value;
                        final percentage = (result['percentage'] as num)
                            .toDouble();
                        final color = _getColorForIndex(index);
                        final isHighlighted = _highlightedIndex == index;

                        return PieChartSectionData(
                          value: percentage,
                          title: '${percentage.toStringAsFixed(1)}%',
                          color: color,
                          radius: isHighlighted ? 60 : 55,
                          titleStyle: TextStyle(
                            fontSize: isHighlighted ? 12.sp : 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _highlightedIndex = null;
                              return;
                            }
                            _highlightedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                // Legend
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _voteResults.asMap().entries.map((entry) {
                        final index = entry.key;
                        final result = entry.value;
                        final color = _getColorForIndex(index);
                        final isHighlighted = _highlightedIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _highlightedIndex = _highlightedIndex == index
                                  ? null
                                  : index;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 2.h),
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? color.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: isHighlighted
                                    ? color
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4.w,
                                  height: 4.w,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        result['title'] as String,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        '${result['vote_count']} votes',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: 9.sp,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }
}
