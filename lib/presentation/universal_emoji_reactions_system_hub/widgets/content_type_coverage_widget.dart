import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class ContentTypeCoverageWidget extends StatelessWidget {
  const ContentTypeCoverageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final contentTypes = [
      {
        'type': 'Elections',
        'icon': Icons.how_to_vote,
        'coverage': 98.7,
        'total_reactions': 456782,
        'description': 'Voting cards, election details',
      },
      {
        'type': 'Posts',
        'icon': Icons.article,
        'coverage': 95.3,
        'total_reactions': 342891,
        'description': 'Social feed posts, creator updates',
      },
      {
        'type': 'Jolts',
        'icon': Icons.video_library,
        'coverage': 92.1,
        'total_reactions': 289456,
        'description': 'Short videos',
      },
      {
        'type': 'Comments',
        'icon': Icons.comment,
        'coverage': 89.4,
        'total_reactions': 187234,
        'description': 'Election comments, post replies',
      },
      {
        'type': 'Direct Messages',
        'icon': Icons.message,
        'coverage': 87.6,
        'total_reactions': 134567,
        'description': '1-on-1 chats, group chats',
      },
      {
        'type': 'Profiles',
        'icon': Icons.person,
        'coverage': 84.2,
        'total_reactions': 98234,
        'description': 'User profiles, creator pages',
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: contentTypes.length,
      itemBuilder: (context, index) {
        final contentType = contentTypes[index];
        return _buildContentTypeCard(theme, contentType);
      },
    );
  }

  Widget _buildContentTypeCard(
    ThemeData theme,
    Map<String, dynamic> contentType,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
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
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  contentType['icon'] as IconData,
                  color: theme.colorScheme.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contentType['type'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      contentType['description'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  '${contentType['coverage']}%',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Reactions',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(contentType['total_reactions'] as int) ~/ 1000}K',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to content type details
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                icon: const Icon(Icons.analytics, size: 16),
                label: Text(
                  'View Details',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
