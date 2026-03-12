import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class QuizCardWidget extends StatefulWidget {
  final Map<String, dynamic> quizData;
  final Function(bool isCorrect, int vpEarned) onAnswered;

  const QuizCardWidget({
    super.key,
    required this.quizData,
    required this.onAnswered,
  });

  @override
  State<QuizCardWidget> createState() => _QuizCardWidgetState();
}

class _QuizCardWidgetState extends State<QuizCardWidget> {
  int? _selectedIndex;
  bool _hasAnswered = false;

  @override
  Widget build(BuildContext context) {
    final question =
        widget.quizData['question']?.toString() ?? 'Trivia Question';
    final options = List<String>.from(
      widget.quizData['options'] as List? ?? ['A', 'B', 'C', 'D'],
    );
    final correctIndex =
        (widget.quizData['correct_index'] as num?)?.toInt() ?? 0;
    final explanation = widget.quizData['explanation']?.toString() ?? '';

    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withAlpha(30),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.quiz,
                        color: Color(0xFFFFD700),
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Quiz',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFD700),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withAlpha(30),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    '+15 VP',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFD700),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Text(
              question,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.5.h),
            ...options.asMap().entries.map((entry) {
              final idx = entry.key;
              final option = entry.value;
              Color? bgColor;
              Color borderColor = Colors.transparent;

              if (_hasAnswered) {
                if (idx == correctIndex) {
                  bgColor = const Color(0xFF4CAF50).withAlpha(30);
                  borderColor = const Color(0xFF4CAF50);
                } else if (idx == _selectedIndex) {
                  bgColor = const Color(0xFFFF6B6B).withAlpha(30);
                  borderColor = const Color(0xFFFF6B6B);
                }
              } else if (idx == _selectedIndex) {
                bgColor = const Color(0xFF6C63FF).withAlpha(30);
                borderColor = const Color(0xFF6C63FF);
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: GestureDetector(
                  onTap: _hasAnswered
                      ? null
                      : () {
                          setState(() {
                            _selectedIndex = idx;
                            _hasAnswered = true;
                          });
                          widget.onAnswered(
                            idx == correctIndex,
                            idx == correctIndex ? 15 : 0,
                          );
                        },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.2.h,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor ?? const Color(0xFF2A2A3E),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: borderColor == Colors.transparent
                                ? const Color(0xFF3A3A4E)
                                : borderColor.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + idx),
                              style: GoogleFonts.inter(
                                color: borderColor == Colors.transparent
                                    ? Colors.white54
                                    : borderColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        if (_hasAnswered && idx == correctIndex)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                            size: 18,
                          ),
                        if (_hasAnswered &&
                            idx == _selectedIndex &&
                            idx != correctIndex)
                          const Icon(
                            Icons.cancel,
                            color: Color(0xFFFF6B6B),
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_hasAnswered && explanation.isNotEmpty)
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: Color(0xFFFFD700),
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        explanation,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_hasAnswered)
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Row(
                  children: [
                    Icon(
                      _selectedIndex == correctIndex
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _selectedIndex == correctIndex
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF6B6B),
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      _selectedIndex == correctIndex
                          ? '+15 VP earned!'
                          : 'Better luck next time!',
                      style: GoogleFonts.inter(
                        color: _selectedIndex == correctIndex
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF6B6B),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
