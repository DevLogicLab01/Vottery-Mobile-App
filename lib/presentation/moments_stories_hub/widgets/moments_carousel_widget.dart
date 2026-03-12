import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

/// Horizontal carousel showing moments from followed users and create button
class MomentsCarouselWidget extends StatelessWidget {
  final List<Map<String, dynamic>> myMoments;
  final List<Map<String, dynamic>> followingMoments;
  final VoidCallback onCreateTap;
  final Function(int) onMomentTap;

  const MomentsCarouselWidget({
    super.key,
    required this.myMoments,
    required this.followingMoments,
    required this.onCreateTap,
    required this.onMomentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12.h,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: 1 + followingMoments.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCreateMomentCard();
          }

          final moment = followingMoments[index - 1];
          return _buildMomentCard(context, moment, index - 1);
        },
      ),
    );
  }

  Widget _buildCreateMomentCard() {
    final currentUser = AuthService.instance.currentUser;
    final hasMyMoments = myMoments.isNotEmpty;

    return GestureDetector(
      onTap: onCreateTap,
      child: Container(
        width: 22.w,
        margin: EdgeInsets.only(right: 3.w),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasMyMoments
                          ? AppTheme.vibrantYellow
                          : Colors.white.withAlpha(77),
                      width: 2,
                    ),
                    image: currentUser?.userMetadata?['avatar_url'] != null
                        ? DecorationImage(
                            image: NetworkImage(
                              currentUser!.userMetadata!['avatar_url'],
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[800],
                  ),
                  child: currentUser?.userMetadata?['avatar_url'] == null
                      ? Icon(Icons.person, color: Colors.white, size: 8.w)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(0.5.w),
                    decoration: BoxDecoration(
                      color: AppTheme.vibrantYellow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: Colors.black, size: 4.w),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Your Moment',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentCard(
    BuildContext context,
    Map<String, dynamic> moment,
    int index,
  ) {
    final creator = moment['creator'] as Map<String, dynamic>?;
    final username = creator?['username'] as String? ?? 'User';
    final avatarUrl = creator?['avatar_url'] as String?;

    return GestureDetector(
      onTap: () => onMomentTap(index),
      child: Container(
        width: 22.w,
        margin: EdgeInsets.only(right: 3.w),
        child: Column(
          children: [
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.vibrantYellow, width: 2),
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[800],
              ),
              child: avatarUrl == null
                  ? Icon(Icons.person, color: Colors.white, size: 8.w)
                  : null,
            ),
            SizedBox(height: 0.5.h),
            Text(
              username,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
