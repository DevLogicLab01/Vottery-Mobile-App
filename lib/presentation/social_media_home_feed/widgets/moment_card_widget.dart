import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart' as theme;
import '../../../widgets/custom_image_widget.dart';

/// Enhanced Live Moment Card Widget
/// Circular avatar with gradient border, expiry countdown, interactive indicator
class MomentCardWidget extends StatefulWidget {
  final Map<String, dynamic> moment;
  final VoidCallback onTap;

  const MomentCardWidget({
    super.key,
    required this.moment,
    required this.onTap,
  });

  @override
  State<MomentCardWidget> createState() => _MomentCardWidgetState();
}

class _MomentCardWidgetState extends State<MomentCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moment = widget.moment;
    final creator = moment['creator'] as Map<String, dynamic>?;
    final username = creator?['username'] as String? ?? 'User';
    final avatarUrl = creator?['avatar_url'] as String?;
    final isViewed = moment['is_viewed'] as bool? ?? false;
    final frameCount = moment['frame_count'] as int? ?? 1;
    final hasInteractive = moment['has_poll'] as bool? ?? false;
    final expiresAt = moment['expires_at'] != null
        ? DateTime.tryParse(moment['expires_at'] as String)
        : null;
    final hoursLeft = expiresAt != null
        ? expiresAt.difference(DateTime.now()).inHours
        : 24;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: isViewed
                  ? Colors.grey.withAlpha(40)
                  : theme.AppThemeColors.electricGold.withAlpha(80),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background preview image
            if (moment['preview_url'] != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: CustomImageWidget(
                    imageUrl: moment['preview_url'] as String,
                    fit: BoxFit.cover,
                    semanticLabel: 'Moment preview by $username',
                  ),
                ),
              ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(60),
                      Colors.transparent,
                      Colors.black.withAlpha(180),
                    ],
                  ),
                ),
              ),
            ),
            // Center: Avatar with gradient border
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _borderController,
                    builder: (context, child) {
                      return Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isViewed
                              ? null
                              : SweepGradient(
                                  startAngle: _borderController.value * 6.28,
                                  colors: [
                                    theme.AppThemeColors.electricGold,
                                    theme.AppThemeColors.neonMint,
                                    theme.AppThemeColors.electricGold,
                                  ],
                                ),
                          color: isViewed ? Colors.grey[400] : null,
                        ),
                        padding: const EdgeInsets.all(2.5),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(
                            child: avatarUrl != null
                                ? CustomImageWidget(
                                    imageUrl: avatarUrl,
                                    fit: BoxFit.cover,
                                    semanticLabel: '$username avatar',
                                  )
                                : Container(
                                    color: theme.AppThemeColors.electricGold
                                        .withAlpha(80),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 6.w,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    username,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Top badges
            Positioned(
              top: 1.5.h,
              right: 2.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (frameCount > 1)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.5.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '$frameCount',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (hasInteractive) ...[
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: theme.AppThemeColors.electricGold,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.how_to_vote_rounded,
                        color: Colors.black,
                        size: 3.w,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Bottom: expiry countdown
            Positioned(
              bottom: 1.5.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: hoursLeft < 6
                        ? const Color(0xFFFF4757).withAlpha(200)
                        : Colors.black.withAlpha(140),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    '${hoursLeft}h left',
                    style: GoogleFonts.inter(
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
      ),
    );
  }
}
