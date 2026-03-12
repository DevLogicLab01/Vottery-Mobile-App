import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart' as theme;
import '../../../widgets/custom_image_widget.dart';

/// Enhanced Creator Spotlight Card Widget
/// Verification badge, earnings display, follow CTA, spotlight glow effect
class CreatorSpotlightCardWidget extends StatefulWidget {
  final Map<String, dynamic> spotlight;

  const CreatorSpotlightCardWidget({super.key, required this.spotlight});

  @override
  State<CreatorSpotlightCardWidget> createState() =>
      _CreatorSpotlightCardWidgetState();
}

class _CreatorSpotlightCardWidgetState extends State<CreatorSpotlightCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _spotlightController;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _spotlightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _spotlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spotlight;
    final name =
        s['display_name'] as String? ?? s['username'] as String? ?? 'Creator';
    final username = s['username'] as String? ?? '@creator';
    final avatarUrl = s['avatar_url'] as String?;
    final coverUrl = s['cover_url'] as String? ?? s['banner_url'] as String?;
    final isVerified = s['verified'] as bool? ?? false;
    final earnings = s['monthly_earnings'] as num? ?? 0;
    final followers = s['follower_count'] as int? ?? 0;
    final tier = s['tier'] as String? ?? 'Bronze';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: const Color(0xFF1A1A2E),
      ),
      child: Stack(
        children: [
          // Cover image
          if (coverUrl != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 45,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20.0),
                ),
                child: CustomImageWidget(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  semanticLabel: '$name cover image',
                ),
              ),
            ),
          // Spotlight sweep animation
          AnimatedBuilder(
            animation: _spotlightController,
            builder: (context, child) {
              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    gradient: SweepGradient(
                      center: Alignment.topLeft,
                      startAngle: _spotlightController.value * 6.28,
                      endAngle: _spotlightController.value * 6.28 + 1.0,
                      colors: [
                        theme.AppThemeColors.electricGold.withAlpha(30),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: coverUrl != null ? 3.h : 0),
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.AppThemeColors.electricGold,
                            const Color(0xFFFF8C00),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.AppThemeColors.electricGold.withAlpha(
                              100,
                            ),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: ClipOval(
                        child: avatarUrl != null
                            ? CustomImageWidget(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                semanticLabel: '$name profile photo',
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
                    if (isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 5.w,
                          height: 5.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1DA1F2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 3.5.w,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 1.h),
                // Name + tier badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.5.w,
                        vertical: 0.2.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getTierColor(tier),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        tier,
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '@$username',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white.withAlpha(160),
                  ),
                ),
                SizedBox(height: 1.5.h),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat('Followers', _formatCount(followers)),
                    Container(
                      width: 1,
                      height: 4.h,
                      color: Colors.white.withAlpha(40),
                    ),
                    _buildStat(
                      'Earnings',
                      '\$${_formatCount(earnings.toInt())}',
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                // Follow CTA
                GestureDetector(
                  onTap: () => setState(() => _isFollowing = !_isFollowing),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 1.2.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: _isFollowing
                          ? null
                          : LinearGradient(
                              colors: [
                                theme.AppThemeColors.electricGold,
                                const Color(0xFFFF8C00),
                              ],
                            ),
                      color: _isFollowing ? Colors.transparent : null,
                      borderRadius: BorderRadius.circular(30.0),
                      border: _isFollowing
                          ? Border.all(
                              color: theme.AppThemeColors.electricGold,
                              width: 1.5,
                            )
                          : null,
                      boxShadow: _isFollowing
                          ? null
                          : [
                              BoxShadow(
                                color: theme.AppThemeColors.electricGold
                                    .withAlpha(80),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                    ),
                    child: Text(
                      _isFollowing ? 'Following ✓' : '⭐ Follow',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: _isFollowing
                            ? theme.AppThemeColors.electricGold
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: theme.AppThemeColors.electricGold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: Colors.white.withAlpha(160),
          ),
        ),
      ],
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'elite':
        return const Color(0xFF7B2FF7);
      case 'vip':
        return const Color(0xFFFFD700);
      case 'gold':
        return const Color(0xFFFF8C00);
      case 'silver':
        return Colors.grey;
      default:
        return const Color(0xFF8B4513);
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
