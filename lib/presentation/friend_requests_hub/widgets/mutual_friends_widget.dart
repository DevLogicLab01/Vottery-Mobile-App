import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../services/social_service.dart';

class MutualFriendsWidget extends StatefulWidget {
  final String userId;
  final int mutualCount;

  const MutualFriendsWidget({
    super.key,
    required this.userId,
    required this.mutualCount,
  });

  @override
  State<MutualFriendsWidget> createState() => _MutualFriendsWidgetState();
}

class _MutualFriendsWidgetState extends State<MutualFriendsWidget> {
  final SocialService _socialService = SocialService.instance;
  List<Map<String, dynamic>> _mutualFriends = [];
  bool _isLoading = false;
  bool _isExpanded = false;

  Future<void> _loadMutualFriends() async {
    if (_mutualFriends.isNotEmpty) {
      setState(() => _isExpanded = !_isExpanded);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mutuals = await _socialService.getMutualFriends(widget.userId);
      setState(() {
        _mutualFriends = mutuals;
        _isExpanded = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load mutual friends error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _loadMutualFriends,
          child: Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 6.w,
                child: Stack(
                  children: List.generate(
                    widget.mutualCount > 3 ? 3 : widget.mutualCount,
                    (index) => Positioned(
                      left: index * 4.w,
                      child: Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 3.w,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  '${widget.mutualCount} mutual friends',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (_isLoading)
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Center(
              child: SizedBox(
                width: 5.w,
                height: 5.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        if (_isExpanded && !_isLoading && _mutualFriends.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 1.h),
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: _mutualFriends.take(5).map((friend) {
                final fullName = friend['full_name'] ?? 'Unknown';
                final avatarUrl = friend['avatar_url'] ?? '';

                return Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 4.w,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        child: avatarUrl.isEmpty
                            ? Icon(Icons.person, size: 4.w)
                            : null,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
