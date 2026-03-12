import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AdSlotMetricsPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> slotMetrics;
  final double totalRevenueToday;
  final double trendVsYesterday;

  const AdSlotMetricsPanelWidget({
    super.key,
    required this.slotMetrics,
    required this.totalRevenueToday,
    required this.trendVsYesterday,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _RevenueCard(
                label: 'Revenue Today',
                value: '\$${totalRevenueToday.toStringAsFixed(2)}',
                color: const Color(0xFF10B981),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _RevenueCard(
                label: 'vs Yesterday',
                value:
                    '${trendVsYesterday >= 0 ? '+' : ''}${trendVsYesterday.toStringAsFixed(1)}%',
                color: trendVsYesterday >= 0
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Ad Slot Performance',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _TableHeader(),
              const Divider(height: 1),
              ...slotMetrics.map((slot) => _SlotRow(slot: slot)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RevenueCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Slot ID',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Impr.',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Fill%',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'Rev.',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final Map<String, dynamic> slot;

  const _SlotRow({required this.slot});

  @override
  Widget build(BuildContext context) {
    final fillRate = (slot['fill_rate'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              slot['slot_id'] as String? ?? '',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: const Color(0xFF374151),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '${slot['impressions'] ?? 0}',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${fillRate.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: fillRate >= 70
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFF59E0B),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '\$${(slot['revenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
