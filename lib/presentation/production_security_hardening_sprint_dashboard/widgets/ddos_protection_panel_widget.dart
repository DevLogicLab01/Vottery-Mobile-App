import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class DDoSProtectionPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> auditLogs;
  final VoidCallback onRunCheck;

  const DDoSProtectionPanelWidget({
    super.key,
    required this.auditLogs,
    required this.onRunCheck,
  });

  @override
  Widget build(BuildContext context) {
    final rateLimitRules = [
      {
        'endpoint': '/api/auth/login',
        'max_requests_per_minute': 10,
        'current_usage': 3,
        'burst_allowance': 15,
        'status': 'normal',
      },
      {
        'endpoint': '/api/votes',
        'max_requests_per_minute': 60,
        'current_usage': 45,
        'burst_allowance': 80,
        'status': 'normal',
      },
      {
        'endpoint': '/api/elections',
        'max_requests_per_minute': 100,
        'current_usage': 95,
        'burst_allowance': 120,
        'status': 'warning',
      },
      {
        'endpoint': '/api/ai/claude',
        'max_requests_per_minute': 20,
        'current_usage': 8,
        'burst_allowance': 25,
        'status': 'normal',
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDDoSMetricsCard(),
          SizedBox(height: 2.h),
          _buildRateLimitTable(rateLimitRules),
          SizedBox(height: 2.h),
          _buildSuspiciousIPsCard(),
          SizedBox(height: 2.h),
          _buildAddRuleSectionCard(context),
        ],
      ),
    );
  }

  Widget _buildDDoSMetricsCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Colors.blue, size: 20),
              SizedBox(width: 2.w),
              Text(
                'DDoS Protection Metrics',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  '1,247',
                  'Blocked Requests',
                  Colors.red,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard('3', 'Suspicious IPs', Colors.orange),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard('0', 'Active Attacks', Colors.green),
              ),
              SizedBox(width: 2.w),
              Expanded(child: _buildMetricCard('99.8%', 'Uptime', Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 8.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRateLimitTable(List<Map<String, dynamic>> rules) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Text(
              'API Rate Limit Rules',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF1A1F3A)),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
              headingTextStyle: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 9.sp,
              ),
              columns: const [
                DataColumn(label: Text('Endpoint')),
                DataColumn(label: Text('Max Req/min')),
                DataColumn(label: Text('Current')),
                DataColumn(label: Text('Burst')),
                DataColumn(label: Text('Status')),
              ],
              rows: rules
                  .map(
                    (rule) => DataRow(
                      cells: [
                        DataCell(
                          Text(
                            rule['endpoint'] as String,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6366F1),
                              fontSize: 9.sp,
                            ),
                          ),
                        ),
                        DataCell(Text('${rule['max_requests_per_minute']}')),
                        DataCell(
                          Text(
                            '${rule['current_usage']}',
                            style: GoogleFonts.inter(
                              color: (rule['status'] == 'warning')
                                  ? Colors.orange
                                  : Colors.white,
                            ),
                          ),
                        ),
                        DataCell(Text('${rule['burst_allowance']}')),
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 1.5.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: (rule['status'] == 'warning')
                                  ? Colors.orange.withAlpha(30)
                                  : Colors.green.withAlpha(30),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              (rule['status'] as String).toUpperCase(),
                              style: GoogleFonts.inter(
                                color: (rule['status'] == 'warning')
                                    ? Colors.orange
                                    : Colors.green,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspiciousIPsCard() {
    final suspiciousIPs = [
      {
        'ip': '192.168.1.100',
        'requests': 847,
        'pattern': 'Rapid auth attempts',
        'blocked': true,
      },
      {
        'ip': '10.0.0.55',
        'requests': 423,
        'pattern': 'Vote manipulation',
        'blocked': true,
      },
      {
        'ip': '172.16.0.22',
        'requests': 201,
        'pattern': 'API scraping',
        'blocked': false,
      },
    ];

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suspicious IPs',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.5.h),
          ...suspiciousIPs.map(
            (ip) => Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(10),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.red.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 16),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ip['ip'] as String,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${ip['requests']} requests — ${ip['pattern']}',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.5.w,
                      vertical: 0.3.h,
                    ),
                    decoration: BoxDecoration(
                      color: (ip['blocked'] as bool)
                          ? Colors.red.withAlpha(30)
                          : Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      (ip['blocked'] as bool) ? 'BLOCKED' : 'MONITORING',
                      style: GoogleFonts.inter(
                        color: (ip['blocked'] as bool)
                            ? Colors.red
                            : Colors.orange,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700,
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

  Widget _buildAddRuleSectionCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF6366F1).withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Rate Limit Rule',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddRuleDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Add Rate Limit Rule',
                style: GoogleFonts.inter(fontSize: 10.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
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

  void _showAddRuleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(
          'Add Rate Limit Rule',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Endpoint',
                labelStyle: GoogleFonts.inter(color: Colors.white54),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              style: GoogleFonts.inter(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Max Requests/Minute',
                labelStyle: GoogleFonts.inter(color: Colors.white54),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: Text('Add', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
