import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class InflationDeflationGaugeWidget extends StatelessWidget {
  final double inflationRate;
  final double circulationVelocity;

  const InflationDeflationGaugeWidget({
    super.key,
    required this.inflationRate,
    required this.circulationVelocity,
  });

  Color get _rateColor {
    final abs = inflationRate.abs();
    if (abs <= 5) return const Color(0xFF4CAF50);
    if (abs <= 15) return const Color(0xFFFFB347);
    return const Color(0xFFFF6B6B);
  }

  String get _rateLabel {
    final abs = inflationRate.abs();
    if (abs <= 5) return 'Stable';
    if (abs <= 15) {
      return inflationRate > 0 ? 'Mild Inflation' : 'Mild Deflation';
    }
    return inflationRate > 0 ? 'High Inflation' : 'High Deflation';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inflation / Deflation Gauge',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _rateColor.withAlpha(26),
                        border: Border.all(color: _rateColor, width: 3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${inflationRate >= 0 ? '+' : ''}${inflationRate.toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: _rateColor,
                            ),
                          ),
                          Text(
                            'Rate',
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _rateColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        _rateLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _rateColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 12.h, color: Colors.grey[200]),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGaugeRow(
                        'Circulation Velocity',
                        circulationVelocity.toStringAsFixed(3),
                        const Color(0xFF6C63FF),
                      ),
                      SizedBox(height: 1.5.h),
                      _buildThresholdRow(
                        'Green Zone',
                        '±5%',
                        const Color(0xFF4CAF50),
                      ),
                      SizedBox(height: 0.8.h),
                      _buildThresholdRow(
                        'Yellow Zone',
                        '±5-15%',
                        const Color(0xFFFFB347),
                      ),
                      SizedBox(height: 0.8.h),
                      _buildThresholdRow(
                        'Red Zone',
                        '>±15%',
                        const Color(0xFFFF6B6B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _buildInflationBar(),
        ],
      ),
    );
  }

  Widget _buildGaugeRow(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdRow(String zone, String range, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          zone,
          style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey[600]),
        ),
        const Spacer(),
        Text(
          range,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInflationBar() {
    final normalized = ((inflationRate + 20) / 40).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inflation Scale',
          style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[500]),
        ),
        SizedBox(height: 0.5.h),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF6B6B),
                    Color(0xFFFFB347),
                    Color(0xFF4CAF50),
                    Color(0xFFFFB347),
                    Color(0xFFFF6B6B),
                  ],
                ),
              ),
            ),
            Positioned(
              left: (normalized * (double.infinity)).isNaN ? 0 : null,
              child: FractionallySizedBox(
                widthFactor: normalized,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _rateColor, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 0.3.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '-20%',
              style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.grey[400]),
            ),
            Text(
              '0%',
              style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.grey[400]),
            ),
            Text(
              '+20%',
              style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.grey[400]),
            ),
          ],
        ),
      ],
    );
  }
}
