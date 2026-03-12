import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class VPMultiplierCalculatorWidget extends StatefulWidget {
  const VPMultiplierCalculatorWidget({super.key});

  @override
  State<VPMultiplierCalculatorWidget> createState() =>
      _VPMultiplierCalculatorWidgetState();
}

class _VPMultiplierCalculatorWidgetState
    extends State<VPMultiplierCalculatorWidget> {
  double _activityLevel = 50.0;

  int _calculateBaseVP() {
    return (_activityLevel * 10).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final baseVP = _calculateBaseVP();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Activity Level',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        Slider(
          value: _activityLevel,
          min: 0,
          max: 100,
          divisions: 20,
          label: '${_activityLevel.toInt()}%',
          activeColor: AppTheme.primaryLight,
          onChanged: (value) {
            setState(() => _activityLevel = value);
          },
        ),
        SizedBox(height: 2.h),
        Text(
          'Estimated Daily Earnings',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        _buildMultiplierRow('Free', 1.0, baseVP, Colors.grey),
        _buildMultiplierRow('Basic', 2.0, baseVP, Color(0xFF3B82F6)),
        _buildMultiplierRow('Pro', 3.0, baseVP, Color(0xFF8B5CF6)),
        _buildMultiplierRow('Elite', 5.0, baseVP, Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildMultiplierRow(
    String tier,
    double multiplier,
    int baseVP,
    Color color,
  ) {
    final earnedVP = (baseVP * multiplier).toInt();

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tier,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            '${multiplier}x',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            '$earnedVP VP',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
