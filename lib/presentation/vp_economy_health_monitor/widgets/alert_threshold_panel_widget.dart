import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AlertThresholdPanelWidget extends StatefulWidget {
  final Map<String, double> thresholds;
  final Function(Map<String, double>)? onSave;

  const AlertThresholdPanelWidget({
    super.key,
    required this.thresholds,
    this.onSave,
  });

  @override
  State<AlertThresholdPanelWidget> createState() =>
      _AlertThresholdPanelWidgetState();
}

class _AlertThresholdPanelWidgetState extends State<AlertThresholdPanelWidget> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'inflation_threshold': TextEditingController(
        text: (widget.thresholds['inflation_threshold'] ?? 15.0).toString(),
      ),
      'circulation_velocity_threshold': TextEditingController(
        text: (widget.thresholds['circulation_velocity_threshold'] ?? 0.05)
            .toString(),
      ),
      'earning_imbalance_threshold': TextEditingController(
        text: (widget.thresholds['earning_imbalance_threshold'] ?? 20.0)
            .toString(),
      ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
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
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: Color(0xFF6C63FF),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Alert Thresholds',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Configure when automated alerts trigger',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[500]),
          ),
          SizedBox(height: 2.h),
          _buildThresholdInput(
            'Inflation Threshold (%)',
            'inflation_threshold',
            'Alert when inflation exceeds this %',
            const Color(0xFFFF6B6B),
          ),
          SizedBox(height: 1.5.h),
          _buildThresholdInput(
            'Circulation Velocity Threshold',
            'circulation_velocity_threshold',
            'VP earned per day / total VP in circulation',
            const Color(0xFF6C63FF),
          ),
          SizedBox(height: 1.5.h),
          _buildThresholdInput(
            'Earning Imbalance Threshold (%)',
            'earning_imbalance_threshold',
            'Alert when earning/spending ratio deviates',
            const Color(0xFFFFB347),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveThresholds,
              icon: const Icon(Icons.save_rounded, size: 16),
              label: Text(
                'Save Thresholds',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdInput(
    String label,
    String key,
    String hint,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        SizedBox(height: 0.5.h),
        TextField(
          controller: _controllers[key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(fontSize: 12.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey[400],
            ),
            filled: true,
            fillColor: color.withAlpha(13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: color.withAlpha(77)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: color.withAlpha(77)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.2.h,
            ),
            suffixIcon: Icon(Icons.edit_rounded, color: color, size: 16),
          ),
        ),
      ],
    );
  }

  void _saveThresholds() {
    final updated = <String, double>{};
    for (final entry in _controllers.entries) {
      updated[entry.key] = double.tryParse(entry.value.text) ?? 0.0;
    }
    widget.onSave?.call(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert thresholds saved successfully'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }
}
