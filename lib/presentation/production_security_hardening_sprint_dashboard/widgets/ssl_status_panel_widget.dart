import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class SSLStatusPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> auditLogs;
  final VoidCallback onRunCheck;

  const SSLStatusPanelWidget({
    super.key,
    required this.auditLogs,
    required this.onRunCheck,
  });

  @override
  Widget build(BuildContext context) {
    final endpoints = [
      {
        'endpoint_url': 'https://vottery2205.builtwithrocket.new',
        'ssl_status': 'valid',
        'certificate_valid_until': '2025-11-15',
        'auto_renewal_enabled': true,
        'protocol': 'TLS 1.3',
        'grade': 'A+',
      },
      {
        'endpoint_url': 'https://api.vottery2205.builtwithrocket.new',
        'ssl_status': 'valid',
        'certificate_valid_until': '2025-11-15',
        'auto_renewal_enabled': true,
        'protocol': 'TLS 1.3',
        'grade': 'A',
      },
      {
        'endpoint_url': 'https://supabase.vottery.io',
        'ssl_status': 'valid',
        'certificate_valid_until': '2025-12-01',
        'auto_renewal_enabled': true,
        'protocol': 'TLS 1.2',
        'grade': 'A',
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(),
          SizedBox(height: 2.h),
          _buildEndpointTable(endpoints),
          SizedBox(height: 2.h),
          _buildCertificateManagement(context),
          SizedBox(height: 2.h),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(30),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Icon(Icons.lock, color: Colors.green, size: 28),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SSL/TLS Enforcement',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'All endpoints enforcing HTTPS-only with TLS 1.2+',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '3/3',
                style: GoogleFonts.inter(
                  color: Colors.green,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Endpoints Secure',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 9.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointTable(List<Map<String, dynamic>> endpoints) {
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
              'Endpoint Security Status',
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
                DataColumn(label: Text('SSL Status')),
                DataColumn(label: Text('Valid Until')),
                DataColumn(label: Text('Protocol')),
                DataColumn(label: Text('Grade')),
                DataColumn(label: Text('Auto-Renew')),
              ],
              rows: endpoints
                  .map(
                    (ep) => DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 35.w,
                            child: Text(
                              ep['endpoint_url'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6366F1),
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 1.5.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(30),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              (ep['ssl_status'] as String).toUpperCase(),
                              style: GoogleFonts.inter(
                                color: Colors.green,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(ep['certificate_valid_until'] as String)),
                        DataCell(Text(ep['protocol'] as String)),
                        DataCell(
                          Text(
                            ep['grade'] as String,
                            style: GoogleFonts.inter(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        DataCell(
                          Icon(
                            (ep['auto_renewal_enabled'] as bool)
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: (ep['auto_renewal_enabled'] as bool)
                                ? Colors.green
                                : Colors.red,
                            size: 16,
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

  Widget _buildCertificateManagement(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Certificate Management',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildCertRow(
            'Primary Certificate',
            '87 days remaining',
            Colors.green,
          ),
          _buildCertRow(
            'Wildcard Certificate',
            '87 days remaining',
            Colors.green,
          ),
          _buildCertRow('API Certificate', '103 days remaining', Colors.green),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility, size: 14),
                  label: Text(
                    'View Details',
                    style: GoogleFonts.inter(fontSize: 10.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1F3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, size: 14),
                  label: Text(
                    'Manual Renew',
                    style: GoogleFonts.inter(fontSize: 10.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
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

  Widget _buildCertRow(String name, String expiry, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.green, size: 14),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 10.sp),
            ),
          ),
          Text(
            expiry,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onRunCheck,
            icon: const Icon(Icons.security, size: 14),
            label: Text(
              'Run SSL Audit',
              style: GoogleFonts.inter(fontSize: 10.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 1.2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
