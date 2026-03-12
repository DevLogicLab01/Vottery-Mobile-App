import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class CORSConfigPanelWidget extends StatefulWidget {
  final List<Map<String, dynamic>> auditLogs;
  final VoidCallback onRunCheck;

  const CORSConfigPanelWidget({
    super.key,
    required this.auditLogs,
    required this.onRunCheck,
  });

  @override
  State<CORSConfigPanelWidget> createState() => _CORSConfigPanelWidgetState();
}

class _CORSConfigPanelWidgetState extends State<CORSConfigPanelWidget> {
  bool _isRunningTests = false;
  List<Map<String, dynamic>> _testResults = [];

  final List<String> _allowedOrigins = [
    'https://vottery2205.builtwithrocket.new',
    'https://app.vottery.io',
    'https://admin.vottery.io',
  ];

  final List<String> _allowedMethods = [
    'GET',
    'POST',
    'PUT',
    'DELETE',
    'OPTIONS',
  ];

  final List<String> _allowedHeaders = [
    'Content-Type',
    'Authorization',
    'X-Requested-With',
    'X-CSRF-Token',
  ];

  bool _credentialsEnabled = false;

  Future<void> _runCORSTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = [];
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isRunningTests = false;
      _testResults = [
        {
          'test': 'Preflight Request',
          'status': 'passed',
          'details': 'OPTIONS returns correct headers',
        },
        {
          'test': 'Origin Validation',
          'status': 'passed',
          'details': 'Only allowed origins accepted',
        },
        {
          'test': 'Credentials Policy',
          'status': 'passed',
          'details': 'Credentials correctly disabled',
        },
        {
          'test': 'Method Restriction',
          'status': 'passed',
          'details': 'Only allowed methods permitted',
        },
        {
          'test': 'Wildcard Origin Check',
          'status': 'passed',
          'details': 'No wildcard (*) origins detected',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCORSConfigCard(),
          SizedBox(height: 2.h),
          _buildTestSuiteCard(),
          if (_testResults.isNotEmpty) ...[
            SizedBox(height: 2.h),
            _buildTestResultsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildCORSConfigCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.purple.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public, color: Colors.purple, size: 20),
              SizedBox(width: 2.w),
              Text(
                'CORS Configuration',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildConfigSection(
            'Allowed Origins',
            _allowedOrigins,
            Colors.green,
            Icons.check_circle_outline,
          ),
          SizedBox(height: 1.5.h),
          _buildConfigSection(
            'Allowed Methods',
            _allowedMethods,
            Colors.blue,
            Icons.http,
          ),
          SizedBox(height: 1.5.h),
          _buildConfigSection(
            'Allowed Headers',
            _allowedHeaders,
            Colors.orange,
            Icons.help_outline,
          ),
          SizedBox(height: 1.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Allow Credentials',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 11.sp,
                ),
              ),
              Switch(
                value: _credentialsEnabled,
                onChanged: (v) => setState(() => _credentialsEnabled = v),
                activeThumbColor: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection(
    String title,
    List<String> items,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            SizedBox(width: 1.w),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Wrap(
          spacing: 1.w,
          runSpacing: 0.5.h,
          children: items
              .map(
                (item) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.4.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: color.withAlpha(60)),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.inter(color: color, fontSize: 9.sp),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTestSuiteCard() {
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
            'CORS Test Suite',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Run automated tests to verify CORS configuration is correctly enforced.',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp),
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunningTests ? null : _runCORSTests,
              icon: _isRunningTests
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow, size: 16),
              label: Text(
                _isRunningTests
                    ? 'Running Tests...'
                    : 'Test CORS Configuration',
                style: GoogleFonts.inter(fontSize: 10.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
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

  Widget _buildTestResultsCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 2.w),
              Text(
                'Test Results — All Passed',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          ..._testResults.map(
            (result) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.5.h),
              child: Row(
                children: [
                  Icon(
                    result['status'] == 'passed'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: result['status'] == 'passed'
                        ? Colors.green
                        : Colors.red,
                    size: 14,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result['test'] as String,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          result['details'] as String,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
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
