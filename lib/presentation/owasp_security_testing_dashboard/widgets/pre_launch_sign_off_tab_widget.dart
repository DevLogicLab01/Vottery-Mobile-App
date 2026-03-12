import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_theme.dart';

class PreLaunchSignOffTabWidget extends StatefulWidget {
  const PreLaunchSignOffTabWidget({super.key});

  @override
  State<PreLaunchSignOffTabWidget> createState() =>
      _PreLaunchSignOffTabWidgetState();
}

class _PreLaunchSignOffTabWidgetState extends State<PreLaunchSignOffTabWidget> {
  final _supabase = Supabase.instance.client;
  final bool _isApproving = false;

  final List<Map<String, dynamic>> _domains = [
    {
      'name': 'OWASP Testing',
      'status': 'approved',
      'approver': 'security@vottery.com',
      'timestamp': '2026-02-27 14:30',
    },
    {
      'name': 'Pen Testing',
      'status': 'approved',
      'approver': 'security@vottery.com',
      'timestamp': '2026-02-27 15:00',
    },
    {
      'name': 'Biometric Compliance',
      'status': 'pending',
      'approver': null,
      'timestamp': null,
    },
    {
      'name': 'Data Residency',
      'status': 'approved',
      'approver': 'compliance@vottery.com',
      'timestamp': '2026-02-27 12:00',
    },
    {
      'name': 'GDPR',
      'status': 'approved',
      'approver': 'legal@vottery.com',
      'timestamp': '2026-02-26 18:00',
    },
    {'name': 'CCPA', 'status': 'pending', 'approver': null, 'timestamp': null},
    {
      'name': 'SSL/TLS',
      'status': 'approved',
      'approver': 'devops@vottery.com',
      'timestamp': '2026-02-27 10:00',
    },
    {
      'name': 'Rate Limiting',
      'status': 'approved',
      'approver': 'devops@vottery.com',
      'timestamp': '2026-02-27 11:00',
    },
  ];

  int get _approvedCount =>
      _domains.where((d) => d['status'] == 'approved').length;
  double get _readinessScore => _approvedCount / _domains.length * 100;
  bool get _allApproved => _approvedCount == _domains.length;

  void _showApprovalDialog(int index) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign Off: ${_domains[index]['name']}',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _domains[index]['status'] = 'rejected';
                _domains[index]['approver'] = 'admin@vottery.com';
                _domains[index]['timestamp'] = DateTime.now()
                    .toString()
                    .substring(0, 16);
              });
              try {
                await _supabase.from('security_sign_offs').insert({
                  'domain_name': _domains[index]['name'],
                  'status': 'rejected',
                  'rejection_reason': reasonController.text,
                  'approval_timestamp': DateTime.now().toIso8601String(),
                });
              } catch (e) {
                debugPrint('Sign off error: $e');
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _domains[index]['status'] = 'approved';
                _domains[index]['approver'] = 'admin@vottery.com';
                _domains[index]['timestamp'] = DateTime.now()
                    .toString()
                    .substring(0, 16);
              });
              try {
                await _supabase.from('security_sign_offs').insert({
                  'domain_name': _domains[index]['name'],
                  'status': 'approved',
                  'approval_timestamp': DateTime.now().toIso8601String(),
                });
              } catch (e) {
                debugPrint('Sign off error: $e');
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Launch Readiness Score
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: _allApproved
                  ? Colors.green.withAlpha(26)
                  : Colors.orange.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _allApproved
                    ? Colors.green.withAlpha(128)
                    : Colors.orange.withAlpha(128),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Launch Readiness Score',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${_readinessScore.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: _allApproved ? Colors.green : Colors.orange,
                  ),
                ),
                Text(
                  '$_approvedCount / ${_domains.length} domains approved',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 10.sp,
                  ),
                ),
                SizedBox(height: 1.h),
                LinearProgressIndicator(
                  value: _readinessScore / 100,
                  backgroundColor: Colors.grey.withAlpha(51),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _allApproved ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Security Domain Sign-Offs',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          ..._domains.asMap().entries.map((entry) {
            final i = entry.key;
            final domain = entry.value;
            final color = _getStatusColor(domain['status']);
            return Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withAlpha(77)),
              ),
              child: Row(
                children: [
                  Icon(
                    domain['status'] == 'approved'
                        ? Icons.check_circle
                        : domain['status'] == 'rejected'
                        ? Icons.cancel
                        : Icons.pending,
                    color: color,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain['name'],
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (domain['approver'] != null)
                          Text(
                            '${domain['approver']} • ${domain['timestamp']}',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondaryLight,
                              fontSize: 9.sp,
                            ),
                          )
                        else
                          Text(
                            'Awaiting approval',
                            style: GoogleFonts.inter(
                              color: Colors.orange,
                              fontSize: 9.sp,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (domain['status'] == 'pending')
                    TextButton(
                      onPressed: () => _showApprovalDialog(i),
                      child: Text(
                        'Sign Off',
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryLight,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _allApproved ? Colors.green : Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              onPressed: _allApproved
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'All security domains approved. Ready for launch!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.rocket_launch, color: Colors.white),
              label: Text(
                _allApproved
                    ? 'Approved for Launch!'
                    : 'Pending ${_domains.length - _approvedCount} approvals',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
