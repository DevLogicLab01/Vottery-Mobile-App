import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class OWASPTestStatusPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> testResults;
  final VoidCallback onRunTests;
  final bool isRunning;

  const OWASPTestStatusPanelWidget({
    super.key,
    required this.testResults,
    required this.onRunTests,
    this.isRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    final testTypes = [
      {
        'name': 'Dependency Check',
        'icon': Icons.inventory_2,
        'color': Colors.blue,
      },
      {'name': 'SQL Injection', 'icon': Icons.storage, 'color': Colors.red},
      {'name': 'XSS Testing', 'icon': Icons.code, 'color': Colors.orange},
      {
        'name': 'CSRF Protection',
        'icon': Icons.security,
        'color': Colors.purple,
      },
      {'name': 'Authentication', 'icon': Icons.lock, 'color': Colors.teal},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OWASP Test Status',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            ElevatedButton.icon(
              onPressed: isRunning ? null : onRunTests,
              icon: isRunning
                  ? SizedBox(
                      width: 4.w,
                      height: 4.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.play_arrow, size: 4.w),
              label: Text(
                isRunning ? 'Running...' : 'Run All Tests',
                style: TextStyle(fontSize: 10.sp),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        ...testTypes.map((type) {
          final result = testResults.firstWhere(
            (r) => r['test_type'] == type['name'],
            orElse: () => {},
          );
          return _buildTestCard(type, result);
        }),
      ],
    );
  }

  Widget _buildTestCard(
    Map<String, dynamic> type,
    Map<String, dynamic> result,
  ) {
    final name = type['name'] as String;
    final icon = type['icon'] as IconData;
    final color = type['color'] as Color;
    final lastRun = result['last_run'] as String? ?? 'Never';
    final findingsCount = result['findings_count'] ?? 0;
    final critical = result['critical_count'] ?? 0;
    final high = result['high_count'] ?? 0;
    final medium = result['medium_count'] ?? 0;
    final low = result['low_count'] ?? 0;
    final status = result['status'] as String? ?? 'pending';

    final statusColor = status == 'passed'
        ? Colors.green
        : status == 'failed'
        ? Colors.red
        : Colors.grey;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Last run: $lastRun',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
              Text(
                '$findingsCount findings',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: findingsCount > 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          if (findingsCount > 0) ...[
            SizedBox(height: 0.5.h),
            Row(
              children: [
                _buildSeverityBadge('C', critical, Colors.red),
                SizedBox(width: 1.w),
                _buildSeverityBadge('H', high, Colors.orange),
                SizedBox(width: 1.w),
                _buildSeverityBadge('M', medium, Colors.amber),
                SizedBox(width: 1.w),
                _buildSeverityBadge('L', low, Colors.blue),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label:$count',
        style: GoogleFonts.inter(
          fontSize: 8.sp,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
