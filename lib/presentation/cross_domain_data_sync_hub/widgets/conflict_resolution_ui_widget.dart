import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/enhanced_empty_state_widget.dart';

class ConflictResolutionUiWidget extends StatelessWidget {
  final List<Map<String, dynamic>> conflicts;
  final Future<void> Function(String conflictId, String strategy) onResolve;
  final Future<void> Function() onRefresh;

  const ConflictResolutionUiWidget({
    super.key,
    required this.conflicts,
    required this.onResolve,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (conflicts.isEmpty) {
      return EnhancedEmptyStateWidget(
        title: 'No Conflicts Detected',
        description: 'All data is synchronized without conflicts',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.all(3.w),
        itemCount: conflicts.length,
        itemBuilder: (context, index) {
          final conflict = conflicts[index];
          return _buildConflictCard(context, conflict);
        },
      ),
    );
  }

  Widget _buildConflictCard(
    BuildContext context,
    Map<String, dynamic> conflict,
  ) {
    final conflictId = conflict['id'] ?? '';
    final contentType = conflict['content_type'] ?? 'unknown';
    final localData = conflict['local_data'] ?? {};
    final serverData = conflict['server_data'] ?? {};
    final detectedAt = conflict['detected_at'] as DateTime?;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withAlpha(26),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conflict in ${contentType.toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    if (detectedAt != null)
                      Text(
                        'Detected ${_formatTimestamp(detectedAt)}',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Side-by-Side Comparison',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDataColumn(
                  title: 'Local Version',
                  data: localData,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildDataColumn(
                  title: 'Server Version',
                  data: serverData,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Resolution Strategy',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: [
              _buildStrategyButton(
                context,
                conflictId: conflictId,
                strategy: 'use_local',
                label: 'Use Local',
                icon: Icons.phone_android,
                color: Colors.blue,
              ),
              _buildStrategyButton(
                context,
                conflictId: conflictId,
                strategy: 'use_server',
                label: 'Use Server',
                icon: Icons.cloud,
                color: Colors.green,
              ),
              _buildStrategyButton(
                context,
                conflictId: conflictId,
                strategy: 'merge',
                label: 'Merge Both',
                icon: Icons.merge,
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataColumn({
    required String title,
    required Map<String, dynamic> data,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 1.h),
          ...data.entries.take(3).map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textPrimaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStrategyButton(
    BuildContext context, {
    required String conflictId,
    required String strategy,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Resolution'),
            content: Text('Apply "$label" strategy to resolve this conflict?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await onResolve(conflictId, strategy);
        }
      },
      icon: Icon(icon, size: 16.sp),
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
