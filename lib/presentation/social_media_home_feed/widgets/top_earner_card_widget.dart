import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

/// Enhanced Top Earner Card Widget
/// Rank badge, animated earnings, growth percentage, follow CTA
class TopEarnerCardWidget extends StatefulWidget {
  final Map<String, dynamic> earner;

  const TopEarnerCardWidget({super.key, required this.earner});

  @override
  State<TopEarnerCardWidget> createState() => _TopEarnerCardWidgetState();
}

class _TopEarnerCardWidgetState extends State<TopEarnerCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _countController;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _countAnimation = CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOut,
    );
    _countController.forward();
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.earner;
    final rank = e['rank'] as int? ?? 1;
    final name =
        e['display_name'] as String? ?? e['username'] as String? ?? 'Creator';
    final avatarUrl = e['avatar_url'] as String?;
    final earnings = (e['total_earnings'] as num? ?? 0).toDouble();
    final growthPct = (e['growth_percentage'] as num? ?? 0).toDouble();
    final isGrowing = growthPct >= 0;
    final followers = e['follower_count'] as int? ?? 0;

    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rank badge
          _buildRankBadge(rank),
          SizedBox(height: 1.h),
          // Avatar
          Container(
            width: 14.w,
            height: 14.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _getRankColor(rank), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: _getRankColor(rank).withAlpha(100),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? CustomImageWidget(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      semanticLabel: '$name profile photo',
                    )
                  : Container(
                      color: _getRankColor(rank).withAlpha(80),
                      child: Icon(Icons.person, color: Colors.white, size: 6.w),
                    ),
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          // Animated earnings
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, child) {
              final displayEarnings = earnings * _countAnimation.value;
              return Text(
                '\$${_formatEarnings(displayEarnings)}',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: _getRankColor(rank),
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          SizedBox(height: 0.3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isGrowing
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isGrowing
                    ? const Color(0xFF2ED573)
                    : const Color(0xFFFF4757),
                size: 3.w,
              ),
              Text(
                '${growthPct.abs().toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: isGrowing
                      ? const Color(0xFF2ED573)
                      : const Color(0xFFFF4757),
                ),
              ),
              SizedBox(width: 2.w),
              Icon(
                Icons.people_rounded,
                color: Colors.white.withAlpha(160),
                size: 3.w,
              ),
              SizedBox(width: 0.5.w),
              Text(
                _formatCount(followers),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.white.withAlpha(180),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    final color = _getRankColor(rank);
    final emoji = rank == 1
        ? '🥇'
        : rank == 2
        ? '🥈'
        : rank == 3
        ? '🥉'
        : '#$rank';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(120), width: 1),
      ),
      child: Text(
        rank <= 3 ? emoji : '#$rank',
        style: GoogleFonts.inter(
          fontSize: rank <= 3 ? 14.sp : 11.sp,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.white.withAlpha(180);
  }

  String _formatEarnings(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(2)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
