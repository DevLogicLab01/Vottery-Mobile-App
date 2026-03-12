import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class ModerationControlsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> moderationQueue;
  final VoidCallback onRefresh;

  const ModerationControlsWidget({
    super.key,
    required this.moderationQueue,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildModerationStatsCard(theme),
        SizedBox(height: 3.h),
        _buildModerationQueueCard(theme),
        SizedBox(height: 3.h),
        _buildAutomatedFilteringCard(theme),
      ],
    );
  }

  Widget _buildModerationStatsCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moderation Statistics',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                theme,
                'Flagged',
                '${moderationQueue.length}',
                Colors.orange,
              ),
              _buildStatColumn(
                theme,
                'Approved',
                '1,234',
                AppTheme.accentLight,
              ),
              _buildStatColumn(theme, 'Removed', '89', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildModerationQueueCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Moderation Queue',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: AppTheme.primaryLight),
                onPressed: onRefresh,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          moderationQueue.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48.sp,
                          color: AppTheme.accentLight,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No items in moderation queue',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: moderationQueue.map((item) {
                    return _buildModerationQueueItem(theme, item);
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildModerationQueueItem(ThemeData theme, Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item['emoji'] as String, style: TextStyle(fontSize: 28.sp)),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['content_type']} • ID: ${item['content_id']}',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      item['reason'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check, size: 16),
                label: Text(
                  'Approve',
                  style: GoogleFonts.inter(fontSize: 11.sp),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentLight,
                ),
              ),
              SizedBox(width: 2.w),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.close, size: 16),
                label: Text(
                  'Remove',
                  style: GoogleFonts.inter(fontSize: 11.sp),
                ),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutomatedFilteringCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automated Filtering',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildFilterToggle(
            theme,
            'Block inappropriate emojis',
            true,
            'Automatically blocks emojis flagged as inappropriate',
          ),
          _buildFilterToggle(
            theme,
            'Spam detection',
            true,
            'Detects and prevents spam reactions',
          ),
          _buildFilterToggle(
            theme,
            'Rate limiting',
            true,
            'Limits reaction frequency per user',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggle(
    ThemeData theme,
    String label,
    bool value,
    String description,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {},
            activeThumbColor: AppTheme.primaryLight,
          ),
        ],
      ),
    );
  }
}
