import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/collaborative_voting_service.dart';

class VotingOptionCardWidget extends StatefulWidget {
  final Map<String, dynamic> option;
  final String roomId;

  const VotingOptionCardWidget({
    super.key,
    required this.option,
    required this.roomId,
  });

  @override
  State<VotingOptionCardWidget> createState() => _VotingOptionCardWidgetState();
}

class _VotingOptionCardWidgetState extends State<VotingOptionCardWidget> {
  final CollaborativeVotingService _votingService =
      CollaborativeVotingService.instance;
  bool _isExpanded = false;
  final List<Map<String, dynamic>> _suggestions = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.option['title'] ?? '';
    final description = widget.option['description'] ?? '';
    final currentVotes = widget.option['current_votes'] ?? 0;
    final percentage = widget.option['percentage'] ?? 0.0;
    final suggestionCount = widget.option['suggestions'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (suggestionCount > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.comment,
                                size: 14.w,
                                color: theme.colorScheme.secondary,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '$suggestionCount',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  Row(
                    children: [
                      Text(
                        '$currentVotes votes',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) _buildSuggestionsSection(theme),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions & Comments',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          _suggestions.isEmpty
              ? Text(
                  'No suggestions yet. Be the first to comment!',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: _suggestions.map((suggestion) {
                    return _buildSuggestionItem(theme, suggestion);
                  }).toList(),
                ),
          SizedBox(height: 1.h),
          ElevatedButton.icon(
            onPressed: () => _showAddSuggestionDialog(),
            icon: Icon(Icons.add_comment, size: 18.w),
            label: Text('Add Suggestion'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 5.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(
    ThemeData theme,
    Map<String, dynamic> suggestion,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        suggestion['suggestion'] ?? '',
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  void _showAddSuggestionDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Suggestion'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter your suggestion...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _votingService.suggestOptionModification(
                  roomId: widget.roomId,
                  optionId: widget.option['id'],
                  suggestion: controller.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _isExpanded = true);
                }
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
