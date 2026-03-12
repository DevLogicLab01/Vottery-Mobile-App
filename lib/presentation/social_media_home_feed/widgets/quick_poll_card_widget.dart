import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class QuickPollCardWidget extends StatefulWidget {
  final Map<String, dynamic> pollData;
  final Function(String option, int vpEarned) onVoted;

  const QuickPollCardWidget({
    super.key,
    required this.pollData,
    required this.onVoted,
  });

  @override
  State<QuickPollCardWidget> createState() => _QuickPollCardWidgetState();
}

class _QuickPollCardWidgetState extends State<QuickPollCardWidget> {
  String? _selectedOption;
  bool _hasVoted = false;

  @override
  Widget build(BuildContext context) {
    final options = List<String>.from(
      widget.pollData['options'] as List? ?? ['A', 'B', 'C', 'D'],
    );
    final question = widget.pollData['question']?.toString() ?? 'Quick Poll';
    final results = Map<String, int>.from(
      widget.pollData['results'] as Map? ?? {},
    );
    final totalVotes = results.values.fold(0, (a, b) => a + b);

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
                    color: const Color(0xFF6C63FF).withAlpha(30),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.poll,
                        color: Color(0xFF6C63FF),
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Quick Poll',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6C63FF),
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
                    '+10 VP',
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
            ...options.map((option) {
              final votes = results[option] ?? 0;
              final percent = totalVotes > 0 ? votes / totalVotes : 0.0;
              final isSelected = _selectedOption == option;

              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: GestureDetector(
                  onTap: _hasVoted
                      ? null
                      : () {
                          setState(() {
                            _selectedOption = option;
                            _hasVoted = true;
                          });
                          widget.onVoted(option, 10);
                        },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C63FF).withAlpha(40)
                          : const Color(0xFF2A2A3E),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                ),
                              ),
                              if (_hasVoted) ...[
                                SizedBox(height: 0.5.h),
                                LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor: Colors.white12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSelected
                                        ? const Color(0xFF6C63FF)
                                        : Colors.white38,
                                  ),
                                  minHeight: 4,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_hasVoted)
                          Text(
                            '${(percent * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? const Color(0xFF6C63FF)
                                  : Colors.white54,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_hasVoted)
              Padding(
                padding: EdgeInsets.only(top: 0.5.h),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '+10 VP earned!',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4CAF50),
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
