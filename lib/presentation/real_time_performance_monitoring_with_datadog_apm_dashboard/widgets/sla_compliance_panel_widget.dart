import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class SlaCompliancePanelWidget extends StatelessWidget {
  const SlaCompliancePanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final slas = [
      {
        'name': 'Query Latency P95',
        'threshold': '< 100ms',
        'current': '87ms',
        'compliant': true,
        'uptime': '99.95%',
      },
      {
        'name': 'Cache Hit Rate',
        'threshold': '> 85%',
        'current': '87%',
        'compliant': true,
        'uptime': '99.82%',
      },
      {
        'name': 'API Availability',
        'threshold': '> 99.9%',
        'current': '99.95%',
        'compliant': true,
        'uptime': '99.95%',
      },
      {
        'name': 'Error Rate',
        'threshold': '< 0.5%',
        'current': '0.3%',
        'compliant': true,
        'uptime': '99.91%',
      },
    ];

    final violations = [
      {
        'time': '14:32',
        'sla': 'Query Latency P95',
        'threshold': '100ms',
        'actual': '134ms',
        'duration': '3m',
      },
      {
        'time': '11:15',
        'sla': 'Cache Hit Rate',
        'threshold': '85%',
        'actual': '82%',
        'duration': '8m',
      },
      {
        'time': '09:44',
        'sla': 'Error Rate',
        'threshold': '0.5%',
        'actual': '0.7%',
        'duration': '2m',
      },
    ];

    final trendData = [
      99.8,
      99.9,
      99.85,
      99.95,
      99.92,
      99.88,
      99.95,
      99.97,
      99.93,
      99.95,
      99.96,
      99.95,
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
              const Icon(
                Icons.verified_outlined,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'SLA Compliance',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withAlpha(38),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '4/4 Compliant',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF22C55E),
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 1.h,
            childAspectRatio: 2.5,
            children: slas.map((s) => _slaCard(s)).toList(),
          ),
          SizedBox(height: 2.h),
          Text(
            'Compliance Trend (30 days)',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 10.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF8B5CF6),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF8B5CF6).withAlpha(26),
                    ),
                  ),
                ],
                minY: 99.5,
                maxY: 100,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Recent Violations',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          ...violations.map((v) => _violationRow(v)),
        ],
      ),
    );
  }

  Widget _slaCard(Map<String, dynamic> s) {
    final compliant = s['compliant'] as bool;
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: compliant
            ? const Color(0xFF22C55E).withAlpha(20)
            : const Color(0xFFEF4444).withAlpha(20),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: compliant
              ? const Color(0xFF22C55E).withAlpha(77)
              : const Color(0xFFEF4444).withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                compliant ? Icons.check_circle : Icons.cancel,
                color: compliant
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
                size: 12,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  s['name'] as String,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 9.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            '${s['current']} / ${s['threshold']}',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 8.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _violationRow(Map<String, dynamic> v) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.4.h),
      child: Row(
        children: [
          Text(
            v['time'] as String,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 9.sp,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              v['sla'] as String,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 9.sp),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.2.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(38),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              '${v['actual']} > ${v['threshold']}',
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontSize: 8.sp,
              ),
            ),
          ),
          SizedBox(width: 1.w),
          Text(
            v['duration'] as String,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }
}
