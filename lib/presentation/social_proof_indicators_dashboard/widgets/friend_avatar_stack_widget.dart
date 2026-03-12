import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FriendAvatarStackWidget extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  final int maxVisible;

  const FriendAvatarStackWidget({
    super.key,
    required this.friends,
    this.maxVisible = 5,
  });

  @override
  Widget build(BuildContext context) {
    final visibleFriends = friends.take(maxVisible).toList();
    final remainingCount = friends.length - maxVisible;

    return SizedBox(
      width: (maxVisible * 6.w) + 2.w,
      height: 8.w,
      child: Stack(
        children: [
          ...visibleFriends.asMap().entries.map((entry) {
            final index = entry.key;
            final friend = entry.value;
            return Positioned(
              left: index * 6.w,
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: friend['avatar'] as String,
                    width: 8.w,
                    height: 8.w,
                    fit: BoxFit.cover,
                    semanticLabel:
                        'Avatar of ${friend['name'] as String? ?? 'friend'}',
                  ),
                ),
              ),
            );
          }),
          if (remainingCount > 0)
            Positioned(
              left: maxVisible * 6.w,
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryLight,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
