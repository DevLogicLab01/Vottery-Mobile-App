import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class OptimizationRecommendationsPanelWidget extends StatefulWidget {
  const OptimizationRecommendationsPanelWidget({super.key});

  @override
  State<OptimizationRecommendationsPanelWidget> createState() =>
      _OptimizationRecommendationsPanelWidgetState();
}

class _OptimizationRecommendationsPanelWidgetState
    extends State<OptimizationRecommendationsPanelWidget> {
  final Set<String> _appliedFixes = {};

  static const List<Map<String, dynamic>> _recommendations = [
    {
      'id': 'rec_1',
      'severity': 'critical',
      'screen': 'Admin Dashboard',
      'issue': 'Screen load time 4800ms (P95)',
      'recommendation': 'Implement lazy loading for Admin Dashboard',
      'steps': [
        'Add RepaintBoundary widgets around heavy widgets',
        'Defer non-critical data loading',
        'Use ListView.builder instead of Column',
      ],
      'impact': '~60% load time reduction',
      'oneClick': true,
    },
    {
      'id': 'rec_2',
      'severity': 'critical',
      'screen': 'Creator Analytics',
      'issue': 'Memory usage 67.8MB (threshold: 50MB)',
      'recommendation': 'Check for memory leaks in Creator Analytics',
      'steps': [
        'Dispose StreamSubscriptions in dispose()',
        'Clear chart data on screen exit',
        'Use weak references for callbacks',
      ],
      'impact': '~35% memory reduction',
      'oneClick': false,
    },
    {
      'id': 'rec_3',
      'severity': 'high',
      'screen': 'Admin Dashboard',
      'issue': 'Average FPS 35 (target: 60)',
      'recommendation': 'Reduce animation complexity in Admin Dashboard',
      'steps': [
        'Use const constructors for static widgets',
        'Profile GPU usage with Flutter DevTools',
        'Replace AnimatedContainer with simple Container',
      ],
      'impact': '~40% FPS improvement',
      'oneClick': true,
    },
    {
      'id': 'rec_4',
      'severity': 'high',
      'screen': 'Social Feed',
      'issue': 'Battery drain 3.8%/min',
      'recommendation': 'Reduce background tasks in Social Feed',
      'steps': [
        'Optimize network calls frequency',
        'Decrease refresh rate from 1s to 5s',
        'Pause video autoplay when not visible',
      ],
      'impact': '~50% battery drain reduction',
      'oneClick': false,
    },
    {
      'id': 'rec_5',
      'severity': 'medium',
      'screen': 'Creator Analytics',
      'issue': 'P95 load time 4100ms',
      'recommendation': 'Optimize image loading in Creator Analytics',
      'steps': [
        'Use CachedNetworkImage for all images',
        'Add placeholder widgets',
        'Compress images before display',
      ],
      'impact': '~25% load time reduction',
      'oneClick': true,
    },
    {
      'id': 'rec_6',
      'severity': 'low',
      'screen': 'Gamification Hub',
      'issue': 'Avg FPS 51 (slightly below 60)',
      'recommendation': 'Use const constructors in Gamification Hub',
      'steps': [
        'Add const keyword to static widgets',
        'Extract repeated widget builds',
      ],
      'impact': '~10% FPS improvement',
      'oneClick': true,
    },
  ];

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      default:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final r in _recommendations) {
      grouped.putIfAbsent(r['severity'], () => []).add(r);
    }
    final order = ['critical', 'high', 'medium', 'low'];
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Optimization Recommendations',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${_recommendations.length} issues',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Automated analysis — prioritized by severity and impact',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54),
          ),
          SizedBox(height: 2.h),
          ...order
              .where((s) => grouped.containsKey(s))
              .map(
                (severity) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSeverityHeader(severity, grouped[severity]!.length),
                    SizedBox(height: 1.h),
                    ...grouped[severity]!.map(
                      (rec) => _buildRecommendationCard(rec),
                    ),
                    SizedBox(height: 1.5.h),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSeverityHeader(String severity, int count) {
    return Row(
      children: [
        Icon(
          _severityIcon(severity),
          color: _severityColor(severity),
          size: 16,
        ),
        SizedBox(width: 1.w),
        Text(
          severity.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: _severityColor(severity),
          ),
        ),
        SizedBox(width: 2.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
          decoration: BoxDecoration(
            color: _severityColor(severity).withAlpha(51),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: _severityColor(severity),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final isApplied = _appliedFixes.contains(rec['id']);
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isApplied
            ? const Color(0xFF22C55E).withAlpha(26)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isApplied
              ? const Color(0xFF22C55E).withAlpha(102)
              : _severityColor(rec['severity']).withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.3.h,
                ),
                decoration: BoxDecoration(
                  color: _severityColor(rec['severity']).withAlpha(51),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  rec['screen'],
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: _severityColor(rec['severity']),
                  ),
                ),
              ),
              const Spacer(),
              if (isApplied)
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF22C55E),
                      size: 14,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Applied',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 0.8.h),
          Text(
            rec['recommendation'],
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            rec['issue'],
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54),
          ),
          SizedBox(height: 1.h),
          ...((rec['steps'] as List<String>).map(
            (step) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.2.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_right,
                    color: Colors.white38,
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      step,
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
          SizedBox(height: 1.h),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF22C55E), size: 14),
              SizedBox(width: 1.w),
              Text(
                rec['impact'],
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const Spacer(),
              if (rec['oneClick'] == true && !isApplied)
                GestureDetector(
                  onTap: () => setState(() => _appliedFixes.add(rec['id'])),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'Apply Fix',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
