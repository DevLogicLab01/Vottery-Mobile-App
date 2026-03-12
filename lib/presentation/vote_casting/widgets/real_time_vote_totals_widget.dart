import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/voting_service.dart';
import '../../../theme/app_theme.dart';

/// Widget for displaying real-time vote totals with visibility enforcement
class RealTimeVoteTotalsWidget extends StatefulWidget {
  final String electionId;
  final bool isCreator;

  const RealTimeVoteTotalsWidget({
    super.key,
    required this.electionId,
    this.isCreator = false,
  });

  @override
  State<RealTimeVoteTotalsWidget> createState() =>
      _RealTimeVoteTotalsWidgetState();
}

class _RealTimeVoteTotalsWidgetState extends State<RealTimeVoteTotalsWidget> {
  final SupabaseClient _client = SupabaseService.instance.client;
  final AuthService _auth = AuthService.instance;

  List<Map<String, dynamic>> _voteResults = [];
  int _totalVotes = 0;
  bool _isLoading = true;
  bool _showResults = false;
  String _voteVisibility = 'hidden';
  RealtimeChannel? _votesChannel;
  RealtimeChannel? _electionChannel;

  @override
  void initState() {
    super.initState();
    _loadVoteResults();
    _subscribeToVoteUpdates();
    _subscribeToVisibilityChanges();
  }

  @override
  void dispose() {
    _votesChannel?.unsubscribe();
    _electionChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadVoteResults() async {
    try {
      // Get election visibility settings
      final electionResponse = await _client
          .from('elections')
          .select('vote_visibility, show_live_results, creator_id')
          .eq('id', widget.electionId)
          .maybeSingle();

      if (electionResponse == null) return;

      final voteVisibility = electionResponse['vote_visibility'] as String?;
      final showLiveResults = electionResponse['show_live_results'] as bool?;
      final creatorId = electionResponse['creator_id'] as String?;

      // Determine if results should be shown
      final isCreator =
          widget.isCreator ||
          (_auth.isAuthenticated && _auth.currentUser!.id == creatorId);
      final shouldShow =
          isCreator || (voteVisibility == 'visible' && showLiveResults == true);

      // Get vote counts
      final votesResponse = await _client
          .from('votes')
          .select('selected_option_id')
          .eq('election_id', widget.electionId);

      final votes = List<Map<String, dynamic>>.from(votesResponse);

      // Get election options
      final optionsResponse = await _client
          .from('election_options')
          .select('id, option_text, description')
          .eq('election_id', widget.electionId)
          .order('display_order', ascending: true);

      final options = List<Map<String, dynamic>>.from(optionsResponse);

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
      final results = options.map((option) {
        final optionId = option['id'] as String;
        final voteCount = voteCounts[optionId] ?? 0;
        final percentage = totalVotes > 0
            ? (voteCount / totalVotes * 100)
            : 0.0;

        return {
          'id': optionId,
          'option_text': option['option_text'],
          'description': option['description'],
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
          _showResults = shouldShow;
          _voteVisibility = voteVisibility ?? 'hidden';
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
        .channel('votes:${widget.electionId}')
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

  void _subscribeToVisibilityChanges() {
    _electionChannel = _client
        .channel('election:${widget.electionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'elections',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.electionId,
          ),
          callback: (payload) {
            _loadVoteResults();
          },
        )
        .subscribe();
  }

  Future<void> _toggleVisibility() async {
    if (_voteVisibility != 'hidden') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visibility cannot be changed back to hidden'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Make Results Visible?'),
        content: Text(
          'This will show real-time vote totals to all voters. This action cannot be reversed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLight,
            ),
            child: Text('Make Visible'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Update election visibility
      await _client
          .from('elections')
          .update({'vote_visibility': 'visible', 'show_live_results': true})
          .eq('id', widget.electionId);

      // Log visibility change
      await _client.rpc(
        'log_visibility_change',
        params: {
          'p_election_id': widget.electionId,
          'p_changed_by': _auth.currentUser!.id,
          'p_previous_state': 'hidden',
          'p_new_state': 'visible',
          'p_reason': 'Creator toggled visibility during voting',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vote totals are now visible to all voters'),
            backgroundColor: AppTheme.accentLight,
          ),
        );
      }

      _loadVoteResults();
    } catch (e) {
      debugPrint('Toggle visibility error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update visibility'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (!_showResults && !widget.isCreator) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.visibility_off, color: Colors.grey.shade600, size: 6.w),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Vote totals are hidden during voting',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppTheme.primaryLight, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Real-Time Vote Totals',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              if (widget.isCreator && _voteVisibility == 'hidden')
                ElevatedButton.icon(
                  onPressed: _toggleVisibility,
                  icon: Icon(Icons.visibility, size: 4.w),
                  label: Text('Show to Voters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Total Votes: $_totalVotes',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          if (widget.isCreator && _isTied()) ...[
            _buildTieRunoffSection(context),
            SizedBox(height: 2.h),
          ],
          ..._voteResults.map((result) {
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          result['option_text'] as String,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                      Text(
                        '${result['vote_count']} votes',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentLight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: LinearProgressIndicator(
                            value: (result['percentage'] as double) / 100,
                            minHeight: 1.h,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.accentLight,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${(result['percentage'] as double).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (widget.isCreator && _voteVisibility == 'hidden') ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Only you can see these results. Voters cannot see totals yet.',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// True if top two (or more) options have the same vote count.
  bool _isTied() {
    if (_voteResults.length < 2) return false;
    final topCount = _voteResults[0]['vote_count'] as int;
    return _voteResults[1]['vote_count'] == topCount;
  }

  /// Option IDs that are tied for the lead (same count as first).
  List<String> _tiedOptionIds() {
    if (_voteResults.isEmpty) return [];
    final topCount = _voteResults[0]['vote_count'] as int;
    return _voteResults
        .where((r) => (r['vote_count'] as int) == topCount)
        .map((r) => r['id'] as String)
        .toList();
  }

  Widget _buildTieRunoffSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: Colors.amber.shade800, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Tied',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Top options have the same vote count. Create a run-off election with only these options.',
            style: TextStyle(fontSize: 11.sp, color: Colors.amber.shade900),
          ),
          SizedBox(height: 1.5.h),
          ElevatedButton.icon(
            onPressed: () => _createRunoff(context),
            icon: Icon(Icons.refresh, size: 4.w),
            label: Text('Create run-off election'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLight,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createRunoff(BuildContext context) async {
    final tiedIds = _tiedOptionIds();
    if (tiedIds.isEmpty) return;
    try {
      final newId = await VotingService.instance.cloneRunoff(
        widget.electionId,
        tiedIds,
      );
      if (!context.mounted) return;
      if (newId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Run-off election created. You can edit it in your dashboard.'),
            backgroundColor: AppTheme.accentLight,
          ),
        );
        _loadVoteResults();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create run-off. Check that you are the creator.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Create runoff error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
