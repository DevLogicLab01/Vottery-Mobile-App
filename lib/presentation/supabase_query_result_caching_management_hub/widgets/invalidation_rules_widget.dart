import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class InvalidationRulesWidget extends StatelessWidget {
  const InvalidationRulesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final rules = [
      {
        'table': 'votes',
        'patterns': ['election_feed:*', 'election_stats:*', 'user_dashboard:*'],
        'color': const Color(0xFFEF4444),
      },
      {
        'table': 'user_profiles',
        'patterns': ['user_profile:*'],
        'color': const Color(0xFF3B82F6),
      },
      {
        'table': 'vp_transactions',
        'patterns': ['user_dashboard:*', 'leaderboard:*'],
        'color': const Color(0xFF8B5CF6),
      },
      {
        'table': 'elections',
        'patterns': ['election_feed:*', 'election_stats:*'],
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 2.w),
              Text(
                'Automatic Invalidation Rules',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Smart invalidation clears affected cache patterns on data mutations',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 10.sp,
            ),
          ),
          SizedBox(height: 2.h),
          ...rules.map((rule) => _ruleCard(rule)),
        ],
      ),
    );
  }

  Widget _ruleCard(Map<String, dynamic> rule) {
    final color = rule['color'] as Color;
    final patterns = rule['patterns'] as List<String>;
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'INSERT/UPDATE on ${rule['table']}',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward,
                color: Color(0xFF94A3B8),
                size: 14,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 1.w,
            runSpacing: 0.5.h,
            children: patterns
                .map(
                  (p) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.5.w,
                      vertical: 0.3.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      p,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 9.sp,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
