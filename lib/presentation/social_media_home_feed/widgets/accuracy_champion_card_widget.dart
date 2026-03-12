import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

/// Enhanced Accuracy Champion Card Widget
/// Accuracy score, prediction count, winning streak, specialization
class AccuracyChampionCardWidget extends StatefulWidget {
  final Map<String, dynamic> champion;

  const AccuracyChampionCardWidget({super.key, required this.champion});

  @override
  State<AccuracyChampionCardWidget> createState() =>
      _AccuracyChampionCardWidgetState();
}

class _AccuracyChampionCardWidgetState extends State<AccuracyChampionCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOut,
    );
    _scoreController.forward();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.champion;
    final name =
        c['display_name'] as String? ?? c['username'] as String? ?? 'Champion';
    final avatarUrl = c['avatar_url'] as String?;
    final accuracyScore = (c['accuracy_score'] as num? ?? 0).toDouble();
    final totalPredictions = c['total_predictions'] as int? ?? 0;
    final winningStreak = c['winning_streak'] as int? ?? 0;
    final specialization = c['specialization'] as String? ?? 'General';

    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FF7), Color(0xFF00D2FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B2FF7).withAlpha(100),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: avatarUrl != null
                  ? CustomImageWidget(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      semanticLabel: '$name champion avatar',
                    )
                  : Container(
                      color: const Color(0xFF7B2FF7).withAlpha(80),
                      child: Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 5.w,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 2.w),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 1.5.w,
                    vertical: 0.2.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2FF7).withAlpha(60),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    specialization,
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFBB86FC),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text('🎯', style: TextStyle(fontSize: 9.sp)),
                    SizedBox(width: 0.5.w),
                    Text(
                      '$totalPredictions predictions',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                    if (winningStreak > 0) ...[
                      SizedBox(width: 2.w),
                      Text('🔥', style: TextStyle(fontSize: 9.sp)),
                      Text(
                        '$winningStreak streak',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF8C00),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Accuracy score
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              final displayScore = accuracyScore * _scoreAnimation.value;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${displayScore.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: _getScoreColor(accuracyScore),
                    ),
                  ),
                  Text(
                    'accuracy',
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      color: Colors.white.withAlpha(140),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return const Color(0xFF2ED573);
    if (score >= 75) return const Color(0xFFFFD700);
    if (score >= 60) return const Color(0xFFFF8C00);
    return const Color(0xFFFF4757);
  }
}
