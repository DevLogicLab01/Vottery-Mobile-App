import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AdMiniGameWidget extends StatelessWidget {
  final Map<String, dynamic> game;
  final VoidCallback onPlay;

  const AdMiniGameWidget({super.key, required this.game, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final gameType = game['game_type'] as String;
    final minReward = game['min_vp_reward'] as int;
    final maxReward = game['max_vp_reward'] as int;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: _getGameGradient(gameType),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getGameIcon(gameType), color: Colors.white, size: 32),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGameTitle(gameType),
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getGameDescription(gameType),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Reward: $minReward-$maxReward VP',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPlay,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Play',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: _getGameColor(gameType),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getGameGradient(String gameType) {
    switch (gameType) {
      case 'spin_wheel':
        return const LinearGradient(
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        );
      case 'memory_match':
        return const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        );
      case 'scratch_card':
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
        );
    }
  }

  Color _getGameColor(String gameType) {
    switch (gameType) {
      case 'spin_wheel':
        return const Color(0xFFf5576c);
      case 'memory_match':
        return const Color(0xFF4facfe);
      case 'scratch_card':
        return const Color(0xFFFFA500);
      default:
        return const Color(0xFFFF6B6B);
    }
  }

  IconData _getGameIcon(String gameType) {
    switch (gameType) {
      case 'spin_wheel':
        return Icons.casino;
      case 'memory_match':
        return Icons.grid_on;
      case 'scratch_card':
        return Icons.card_giftcard;
      default:
        return Icons.games;
    }
  }

  String _getGameTitle(String gameType) {
    switch (gameType) {
      case 'spin_wheel':
        return 'Spin the Wheel';
      case 'memory_match':
        return 'Memory Match';
      case 'scratch_card':
        return 'Scratch Card';
      default:
        return 'Mini Game';
    }
  }

  String _getGameDescription(String gameType) {
    switch (gameType) {
      case 'spin_wheel':
        return 'Spin for random VP rewards';
      case 'memory_match':
        return 'Match 8 cards to win VP';
      case 'scratch_card':
        return 'Scratch to reveal instant rewards';
      default:
        return 'Play to earn VP';
    }
  }
}
