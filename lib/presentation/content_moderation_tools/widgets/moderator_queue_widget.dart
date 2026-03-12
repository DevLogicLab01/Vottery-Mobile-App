import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_icon_widget.dart';
import './flagged_content_card_widget.dart';

class ModeratorQueueWidget extends StatefulWidget {
  final VoidCallback onItemProcessed;

  const ModeratorQueueWidget({super.key, required this.onItemProcessed});

  @override
  State<ModeratorQueueWidget> createState() => _ModeratorQueueWidgetState();
}

class _ModeratorQueueWidgetState extends State<ModeratorQueueWidget> {
  final _client = SupabaseService.instance.client;
  String _selectedSeverity = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildSeverityFilter(context),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getQueueStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: EdgeInsets.all(4.w),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return FlaggedContentCardWidget(
                    content: snapshot.data![index],
                    onApprove: () =>
                        _handleApprove(snapshot.data![index]['id']),
                    onRemove: () => _handleRemove(snapshot.data![index]['id']),
                    onEscalate: () =>
                        _handleEscalate(snapshot.data![index]['id']),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityFilter(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Text(
            'Filter by severity:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  _buildFilterChip('critical', 'Critical'),
                  _buildFilterChip('high', 'High'),
                  _buildFilterChip('medium', 'Medium'),
                  _buildFilterChip('low', 'Low'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedSeverity == value;

    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedSeverity = value);
        },
        backgroundColor: theme.colorScheme.surface,
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'check_circle',
            color: theme.disabledColor,
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'Queue is empty',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getQueueStream() {
    var query = _client
        .from('content_moderation_logs')
        .stream(primaryKey: ['id'])
        .eq('moderation_action', 'pending_review');

    if (_selectedSeverity != 'all') {
      // Filter by risk score ranges based on severity
      // This is a simplified approach - adjust ranges as needed
    }

    return query.order('created_at', ascending: false);
  }

  Future<void> _handleApprove(String contentId) async {
    try {
      await _client
          .from('content_moderation_logs')
          .update({
            'moderation_action': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contentId);

      widget.onItemProcessed();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Content approved')));
      }
    } catch (e) {
      debugPrint('Approve content error: $e');
    }
  }

  Future<void> _handleRemove(String contentId) async {
    try {
      await _client
          .from('content_moderation_logs')
          .update({
            'moderation_action': 'removed',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contentId);

      widget.onItemProcessed();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Content removed')));
      }
    } catch (e) {
      debugPrint('Remove content error: $e');
    }
  }

  Future<void> _handleEscalate(String contentId) async {
    try {
      await _client
          .from('content_moderation_logs')
          .update({
            'moderation_action': 'escalated',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contentId);

      widget.onItemProcessed();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Content escalated')));
      }
    } catch (e) {
      debugPrint('Escalate content error: $e');
    }
  }
}
