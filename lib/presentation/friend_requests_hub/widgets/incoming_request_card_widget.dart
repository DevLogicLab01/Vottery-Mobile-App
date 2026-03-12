import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import './mutual_friends_widget.dart';

/// Incoming Request Card Widget - Display incoming friend requests with actions
class IncomingRequestCardWidget extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onIgnore;
  final bool isSelected;
  final VoidCallback? onToggleSelection;
  final bool isBulkMode;

  const IncomingRequestCardWidget({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onIgnore,
    this.isSelected = false,
    this.onToggleSelection,
    this.isBulkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requester = request['requester'] ?? {};
    final fullName = requester['full_name'] ?? 'Unknown User';
    final username = requester['username'] ?? '';
    final avatarUrl = requester['avatar_url'] ?? '';
    final mutualFriends = requester['mutual_friends_count'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha(26)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
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
              if (isBulkMode)
                Padding(
                  padding: EdgeInsets.only(right: 3.w),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelection?.call(),
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
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
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(0.5.w),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 3.w,
                      ),
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
                      style: google_fonts.GoogleFonts.inter(
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
                        style: google_fonts.GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (mutualFriends > 0)
                      Text(
                        '$mutualFriends mutual friends',
                        style: google_fonts.GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (mutualFriends > 0) ...[
            SizedBox(height: 2.h),
            MutualFriendsWidget(
              userId: requester['id'] ?? '',
              mutualCount: mutualFriends,
            ),
          ],
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Accept',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Decline',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: onIgnore,
                icon: Icon(
                  Icons.more_horiz,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Ignore',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
