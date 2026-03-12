import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class JoltsGuessGameCardWidget extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(String guess, int vpEarned) onGuessed;

  const JoltsGuessGameCardWidget({
    super.key,
    required this.gameData,
    required this.onGuessed,
  });

  @override
  State<JoltsGuessGameCardWidget> createState() =>
      _JoltsGuessGameCardWidgetState();
}

class _JoltsGuessGameCardWidgetState extends State<JoltsGuessGameCardWidget> {
  String? _selectedGuess;
  bool _hasGuessed = false;
  bool _isCorrect = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.gameData['title']?.toString() ?? 'Jolts Outcome';
    final thumbnailUrl = widget.gameData['thumbnail_url']?.toString() ?? '';
    final correctAnswer = widget.gameData['correct_answer']?.toString();
    final crowdVote = widget.gameData['crowd_vote']?.toString() ?? 'Yes';

    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Stack(
              children: [
                thumbnailUrl.isNotEmpty
                    ? Image.network(
                        thumbnailUrl,
                        height: 18.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 18.h,
                          color: const Color(0xFF2A2A3E),
                          child: const Icon(
                            Icons.play_circle,
                            color: Colors.white38,
                            size: 48,
                          ),
                        ),
                      )
                    : Container(
                        height: 18.h,
                        color: const Color(0xFF2A2A3E),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle,
                            color: Colors.white38,
                            size: 48,
                          ),
                        ),
                      ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withAlpha(200),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: Colors.white, size: 12),
                        Text(
                          ' Jolts Guess',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withAlpha(200),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      '+20 VP',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Will it succeed?',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.5.h),
                if (!_hasGuessed)
                  Row(
                    children: [
                      Expanded(
                        child: _buildGuessButton(
                          'Yes',
                          const Color(0xFF4CAF50),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: _buildGuessButton('No', const Color(0xFFFF6B6B)),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: _buildGuessButton(
                          'Maybe',
                          const Color(0xFFFFB347),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isCorrect ? Icons.check_circle : Icons.cancel,
                            color: _isCorrect
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF6B6B),
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            _isCorrect
                                ? '+20 VP earned! Great guess!'
                                : 'Not quite! Crowd voted: $crowdVote',
                            style: GoogleFonts.inter(
                              color: _isCorrect
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF6B6B),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Your guess: $_selectedGuess | Crowd: $crowdVote',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuessButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () {
        final correctAnswer =
            widget.gameData['correct_answer']?.toString() ?? 'Yes';
        final correct = label == correctAnswer;
        setState(() {
          _selectedGuess = label;
          _hasGuessed = true;
          _isCorrect = correct;
        });
        widget.onGuessed(label, correct ? 20 : 0);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(40),
        foregroundColor: color,
        side: BorderSide(color: color.withAlpha(100)),
        padding: EdgeInsets.symmetric(vertical: 1.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}
