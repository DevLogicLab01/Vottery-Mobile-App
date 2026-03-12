import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ApiResponseCorrelationPanelWidget extends StatelessWidget {
  const ApiResponseCorrelationPanelWidget({super.key});

  static const List<Map<String, dynamic>> _apiData = [
    {
      'endpoint': '/api/elections/feed',
      'avgMs': 145,
      'calls': 1240,
      'impact': 'High',
      'screen': 'Vote Dashboard',
    },
    {
      'endpoint': '/api/creator/analytics',
      'avgMs': 380,
      'calls': 420,
      'impact': 'Critical',
      'screen': 'Creator Analytics',
    },
    {
      'endpoint': '/api/users/profile',
      'avgMs': 65,
      'calls': 3200,
      'impact': 'Low',
      'screen': 'Multiple',
    },
    {
      'endpoint': '/api/leaderboard',
      'avgMs': 210,
      'calls': 890,
      'impact': 'Medium',
      'screen': 'Social Feed',
    },
    {
      'endpoint': '/api/wallet/balance',
      'avgMs': 88,
      'calls': 650,
      'impact': 'Low',
      'screen': 'Wallet',
    },
    {
      'endpoint': '/api/admin/metrics',
      'avgMs': 520,
      'calls': 180,
      'impact': 'Critical',
      'screen': 'Admin Dashboard',
    },
  ];

  Color _impactColor(String impact) {
    switch (impact) {
      case 'Critical':
        return const Color(0xFFEF4444);
      case 'High':
        return const Color(0xFFF97316);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Response Correlation',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Correlating API calls to screen load times | Identifying bottlenecks',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white54),
          ),
          SizedBox(height: 2.h),
          _buildGanttTimeline(),
          SizedBox(height: 2.h),
          _buildEndpointTable(),
          SizedBox(height: 2.h),
          _buildCorrelationHeatmap(),
        ],
      ),
    );
  }

  Widget _buildGanttTimeline() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Call Timeline During Screen Load (Vote Dashboard)',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildTimelineBar('Auth Check', 0.0, 0.08, const Color(0xFF3B82F6)),
          _buildTimelineBar(
            'User Profile',
            0.05,
            0.18,
            const Color(0xFF8B5CF6),
          ),
          _buildTimelineBar(
            'Elections Feed',
            0.15,
            0.55,
            const Color(0xFFF59E0B),
          ),
          _buildTimelineBar('Leaderboard', 0.20, 0.45, const Color(0xFF22C55E)),
          _buildTimelineBar(
            'Notifications',
            0.50,
            0.70,
            const Color(0xFFEF4444),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['0ms', '250ms', '500ms', '750ms', '1000ms']
                .map(
                  (t) => Text(
                    t,
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      color: Colors.white38,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineBar(
    String label,
    double start,
    double end,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.4.h),
      child: Row(
        children: [
          SizedBox(
            width: 20.w,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(height: 3.h, color: Colors.white.withOpacity(0.08)),
                    Positioned(
                      left: constraints.maxWidth * start,
                      width: constraints.maxWidth * (end - start),
                      child: Container(
                        height: 3.h,
                        decoration: BoxDecoration(
                          color: color.withAlpha(204),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${((end - start) * 1000).toInt()}ms',
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointTable() {
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
                  flex: 4,
                  child: Text(
                    'Endpoint',
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
                    'Avg (ms)',
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
                    'Calls',
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
                    'Impact',
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
          ..._apiData.map(
            (row) => Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      row['endpoint'],
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${row['avgMs']}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: row['avgMs'] > 200
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${row['calls']}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.5.w,
                        vertical: 0.2.h,
                      ),
                      decoration: BoxDecoration(
                        color: _impactColor(row['impact']).withAlpha(51),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        row['impact'],
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: _impactColor(row['impact']),
                        ),
                      ),
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

  Widget _buildCorrelationHeatmap() {
    final screens = ['Vote', 'Feed', 'Creator', 'Wallet', 'Admin'];
    final apis = ['Elections', 'Profile', 'Leader', 'Analytics', 'Wallet'];
    final values = [
      [0.9, 0.3, 0.2, 0.1, 0.1],
      [0.4, 0.8, 0.6, 0.1, 0.1],
      [0.2, 0.5, 0.1, 0.9, 0.1],
      [0.1, 0.3, 0.1, 0.1, 0.9],
      [0.3, 0.4, 0.2, 0.7, 0.2],
    ];
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Correlation Heatmap (API → Screen Impact)',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              SizedBox(width: 12.w),
              ...apis.map(
                (a) => Expanded(
                  child: Text(
                    a,
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      color: Colors.white54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          ...screens.asMap().entries.map(
            (se) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.3.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 12.w,
                    child: Text(
                      se.value,
                      style: GoogleFonts.inter(
                        fontSize: 8.sp,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  ...values[se.key].map(
                    (v) => Expanded(
                      child: Container(
                        height: 4.h,
                        margin: EdgeInsets.all(0.5.w),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            Colors.transparent,
                            const Color(0xFFEF4444),
                            v,
                          ),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Center(
                          child: Text(
                            '${(v * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 7.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
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