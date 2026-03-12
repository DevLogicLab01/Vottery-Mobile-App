import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class RevenueStreamsListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> streams;

  const RevenueStreamsListWidget({super.key, required this.streams});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF313244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Streams',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.5.h),
          ...streams.map((stream) => _buildStreamCard(stream)),
        ],
      ),
    );
  }

  Widget _buildStreamCard(Map<String, dynamic> stream) {
    final revenue = stream['revenue'] as double? ?? 0;
    final target = stream['target'] as double? ?? 1;
    final trend = stream['trend'] as double? ?? 0;
    final isPositive = trend >= 0;
    final color = Color(stream['color'] as int? ?? 0xFF89B4FA);
    final progress = (revenue / target).clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.only(bottom: 1.2.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Icon(
                  stream['icon'] as IconData? ?? Icons.monetization_on,
                  color: color,
                  size: 16,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream['name'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      stream['subtitle'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.white38,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${revenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: isPositive
                            ? const Color(0xFFA6E3A1)
                            : const Color(0xFFF38BA8),
                      ),
                      Text(
                        '${trend.abs().toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: isPositive
                              ? const Color(0xFFA6E3A1)
                              : const Color(0xFFF38BA8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF313244),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% of target',
                style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
