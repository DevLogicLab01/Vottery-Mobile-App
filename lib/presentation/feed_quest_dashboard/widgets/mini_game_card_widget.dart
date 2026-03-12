import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class MiniGameCardWidget extends StatelessWidget {
  final Map<String, dynamic> game;
  final VoidCallback onPlay;

  const MiniGameCardWidget({
    super.key,
    required this.game,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGameGradient(game['game_type'] as String),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(game['icon'] as IconData, color: Colors.white, size: 40),
          SizedBox(height: 2.h),
          Text(
            game['title'] as String,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          Text(
            game['description'] as String,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.white.withAlpha(230),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${game['vp_reward']} VP',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Play',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _getGameColor(game['game_type'] as String),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGameGradient(String gameType) {
    switch (gameType) {
      case 'quick_poll':
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case 'trivia_quiz':
        return [const Color(0xFFf093fb), const Color(0xFFf5576c)];
      case 'prediction_card':
        return [const Color(0xFF4facfe), const Color(0xFF00f2fe)];
      default:
        return [const Color(0xFF6A11CB), const Color(0xFF2575FC)];
    }
  }

  Color _getGameColor(String gameType) {
    switch (gameType) {
      case 'quick_poll':
        return const Color(0xFF667eea);
      case 'trivia_quiz':
        return const Color(0xFFf5576c);
      case 'prediction_card':
        return const Color(0xFF4facfe);
      default:
        return const Color(0xFF6A11CB);
    }
  }
}
