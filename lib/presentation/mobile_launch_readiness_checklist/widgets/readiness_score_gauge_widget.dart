import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;

class ReadinessScoreGaugeWidget extends StatelessWidget {
  final int score;
  final Map<String, int> componentScores;
  const ReadinessScoreGaugeWidget({
    super.key,
    required this.score,
    required this.componentScores,
  });

  Color get _scoreColor {
    if (score >= 90) return const Color(0xFF10B981);
    if (score >= 75) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _scoreLabel {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Readiness Score',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: 35.w,
            height: 35.w,
            child: CustomPaint(
              painter: _GaugePainter(score: score, color: _scoreColor),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor,
                      ),
                    ),
                    Text(
                      _scoreLabel,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Score Breakdown',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 1.h),
          ...componentScores.entries.map(
            (entry) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key, style: TextStyle(fontSize: 11.sp)),
                  ),
                  SizedBox(
                    width: 20.w,
                    child: LinearProgressIndicator(
                      value: entry.value / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        entry.value >= 90
                            ? const Color(0xFF10B981)
                            : entry.value >= 75
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444),
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${entry.value}%',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final Color color;
  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 12.0;
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5 * (score / 100),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
