import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;

class FrameRatePanelWidget extends StatelessWidget {
  const FrameRatePanelWidget({super.key});

  static const List<Map<String, dynamic>> _fpsData = [
    {
      'screen': 'Vote Dashboard',
      'min': 52,
      'avg': 58,
      'max': 60,
      'dropped': 12,
    },
    {'screen': 'Social Feed', 'min': 38, 'avg': 47, 'max': 60, 'dropped': 45},
    {
      'screen': 'Creator Analytics',
      'min': 28,
      'avg': 38,
      'max': 55,
      'dropped': 89,
    },
    {
      'screen': 'Election Studio',
      'min': 55,
      'avg': 59,
      'max': 60,
      'dropped': 5,
    },
    {
      'screen': 'Wallet Dashboard',
      'min': 58,
      'avg': 60,
      'max': 60,
      'dropped': 2,
    },
    {
      'screen': 'Admin Dashboard',
      'min': 22,
      'avg': 35,
      'max': 52,
      'dropped': 120,
    },
    {
      'screen': 'Gamification Hub',
      'min': 42,
      'avg': 51,
      'max': 60,
      'dropped': 32,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frame Rate Monitoring',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Target: 60 FPS | Screens below 45 FPS flagged for optimization',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54),
          ),
          SizedBox(height: 2.h),
          _buildFPSGauge(),
          SizedBox(height: 2.h),
          _buildFPSTable(),
          SizedBox(height: 2.h),
          _buildJankyScreens(),
        ],
      ),
    );
  }

  Widget _buildFPSGauge() {
    const currentFPS = 52.0;
    const maxFPS = 60.0;
    final angle = (currentFPS / maxFPS) * math.pi;
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            'Real-time FPS Gauge',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 15.h,
            child: CustomPaint(
              painter: _GaugePainter(value: currentFPS, max: maxFPS),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${currentFPS.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                      Text(
                        'FPS',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFPSStat('Min', '22', const Color(0xFFEF4444)),
              _buildFPSStat('Avg', '52', const Color(0xFF22C55E)),
              _buildFPSStat('Target', '60', Colors.white54),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFPSStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildFPSTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Screen',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Min',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Avg',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Max',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Dropped',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._fpsData.map((row) {
            final isJanky = row['avg'] < 45;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isJanky
                    ? const Color(0xFFEF4444).withAlpha(13)
                    : Colors.transparent,
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        if (isJanky)
                          const Icon(
                            Icons.warning_amber,
                            color: Color(0xFFEF4444),
                            size: 12,
                          ),
                        if (isJanky) SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            row['screen'],
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: isJanky
                                  ? const Color(0xFFEF4444)
                                  : Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${row['min']}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${row['avg']}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: row['avg'] < 45
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${row['max']}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${row['dropped']} frames',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: row['dropped'] > 50
                            ? const Color(0xFFEF4444)
                            : Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildJankyScreens() {
    final janky = _fpsData.where((d) => d['avg'] < 45).toList();
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: Color(0xFFEF4444), size: 16),
              SizedBox(width: 1.w),
              Text(
                'Janky Screens (FPS < 45)',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ...janky.map(
            (d) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.5.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      d['screen'],
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Avg ${d['avg']} FPS',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${d['dropped']} dropped',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.white54,
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
  final double value;
  final double max;
  const _GaugePainter({required this.value, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.75);
    final radius = size.width * 0.4;
    final bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * (value / max),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}