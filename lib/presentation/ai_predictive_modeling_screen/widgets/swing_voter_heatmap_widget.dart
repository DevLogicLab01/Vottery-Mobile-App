import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Swing Voter Heatmap Widget
/// Geographic heatmap highlighting persuadable voter segments
class SwingVoterHeatmapWidget extends StatelessWidget {
  final List<Map<String, dynamic>> swingVoters;
  final String electionId;

  const SwingVoterHeatmapWidget({
    super.key,
    required this.swingVoters,
    required this.electionId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (swingVoters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 15.w,
              color: Colors.grey.withAlpha(77),
            ),
            SizedBox(height: 2.h),
            Text(
              'No Swing Voters Identified',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Swing Voter Analysis',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          '${swingVoters.length} persuadable voters identified',
          style: TextStyle(
            fontSize: 13.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        SizedBox(height: 2.h),
        ...swingVoters
            .take(10)
            .map((voter) => _buildSwingVoterCard(voter, theme)),
      ],
    );
  }

  Widget _buildSwingVoterCard(Map<String, dynamic> voter, ThemeData theme) {
    final persuadability = voter['persuadability_score'] ?? 0.0;
    final color = _getPersuadabilityColor(persuadability);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77), width: 2.0),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.person, color: color, size: 6.w),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voter ${voter['user_id']?.toString().substring(0, 8) ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Persuadability: ${persuadability.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _getPersuadabilityLabel(persuadability),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPersuadabilityColor(double score) {
    if (score >= 80) return Colors.red;
    if (score >= 70) return Colors.orange;
    if (score >= 60) return Colors.amber;
    return Colors.green;
  }

  String _getPersuadabilityLabel(double score) {
    if (score >= 80) return 'High';
    if (score >= 70) return 'Medium';
    if (score >= 60) return 'Low';
    return 'Stable';
  }
}
