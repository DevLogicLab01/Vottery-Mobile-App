import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class CircuitBreakerStatusWidget extends StatelessWidget {
  final List<Map<String, dynamic>> circuitBreakers;
  final VoidCallback? onRollback;

  const CircuitBreakerStatusWidget({
    super.key,
    required this.circuitBreakers,
    this.onRollback,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Circuit Breaker States',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            if (onRollback != null)
              ElevatedButton.icon(
                onPressed: onRollback,
                icon: Icon(Icons.undo, size: 4.w),
                label: Text(
                  'Rollback All',
                  style: GoogleFonts.inter(fontSize: 10.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
              ),
          ],
        ),
        SizedBox(height: 1.h),
        if (circuitBreakers.isEmpty)
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.green.withAlpha(80)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  'All circuit breakers closed - system healthy',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          )
        else
          ...circuitBreakers.map((cb) => _buildBreakerCard(cb)),
      ],
    );
  }

  Widget _buildBreakerCard(Map<String, dynamic> cb) {
    final isOpen = cb['state'] == 'open';
    final color = isOpen ? Colors.red : Colors.green;
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(isOpen ? Icons.power_off : Icons.power, color: color, size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cb['service_name'] ?? 'Unknown Service',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  'State: ${cb['state']?.toUpperCase() ?? 'UNKNOWN'} | '
                  'Rate Limiting: ${cb['rate_limiting_enabled'] == true ? "ON" : "OFF"}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              isOpen ? 'OPEN' : 'CLOSED',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
