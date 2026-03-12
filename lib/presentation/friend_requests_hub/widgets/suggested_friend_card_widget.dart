import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SuggestedFriendCardWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSendRequest;

  const SuggestedFriendCardWidget({
    super.key,
    required this.user,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = user['full_name'] ?? 'Unknown User';
    final username = user['username'] ?? '';
    final avatarUrl = user['avatar_url'] ?? '';
    final mutualFriends = user['mutual_friends'] ?? 0;
    final sharedGroups = user['shared_groups'] ?? 0;
    final matchScore = user['match_score'] ?? 0;
    final reason = user['reason'] ?? '';
    final location = user['location'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 8.w,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? Icon(Icons.person, size: 8.w)
                        : null,
                  ),
                  if (matchScore >= 90)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(0.5.w),
                        decoration: BoxDecoration(
                          color: AppTheme.vibrantYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.star, color: Colors.white, size: 3.w),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (location.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 3.w,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (reason.isNotEmpty)
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 4.w,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 2.h),
          Row(
            children: [
              if (mutualFriends > 0)
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.people,
                    '$mutualFriends mutual',
                  ),
                ),
              if (sharedGroups > 0)
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.groups,
                    '$sharedGroups groups',
                  ),
                ),
              if (matchScore > 0)
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.analytics,
                    '$matchScore% match',
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSendRequest,
              icon: const Icon(Icons.person_add),
              label: Text(
                'Add Friend',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 4.w, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(width: 1.w),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
