import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class RollbackProceduresPanelWidget extends StatefulWidget {
  const RollbackProceduresPanelWidget({super.key});

  @override
  State<RollbackProceduresPanelWidget> createState() =>
      _RollbackProceduresPanelWidgetState();
}

class _RollbackProceduresPanelWidgetState
    extends State<RollbackProceduresPanelWidget> {
  String _selectedVersion = 'v2.4.0';
  bool _isExecuting = false;

  final List<String> _availableVersions = [
    'v2.4.0',
    'v2.3.9',
    'v2.3.8',
    'v2.3.7',
    'v2.3.6',
  ];

  final List<Map<String, dynamic>> _rollbackHistory = [
    {
      'from': 'v2.3.9',
      'to': 'v2.3.8',
      'timestamp': '2026-02-25 10:15',
      'executed_by': 'admin@vottery.com',
      'reason': 'Payment processing regression',
      'status': 'completed',
      'affected_users': 8420,
    },
  ];

  final Map<String, dynamic> _impactAnalysis = {
    'affected_users': 12847,
    'estimated_downtime': '< 30 seconds',
    'data_migration_needed': false,
    'risk_level': 'Low',
  };

  void _executeRollback() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Confirm Rollback',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rolling back from v2.4.1 to $_selectedVersion. This action requires admin approval.',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Reason for Rollback',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Execute Rollback'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isExecuting = true);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _rollbackHistory.insert(0, {
            'from': 'v2.4.1',
            'to': _selectedVersion,
            'timestamp': DateTime.now().toString().substring(0, 16),
            'executed_by': 'admin@vottery.com',
            'reason': reasonController.text.isEmpty
                ? 'Manual rollback'
                : reasonController.text,
            'status': 'completed',
            'affected_users': 12847,
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rollback to $_selectedVersion completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
            'Rollback Procedures',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withAlpha(77)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Rollback Target',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedVersion,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Target Version',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  items: _availableVersions
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedVersion = v!),
                ),
                SizedBox(height: 1.5.h),
                Text(
                  'Impact Analysis',
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                _buildImpactRow(
                  'Affected Users',
                  _impactAnalysis['affected_users'].toString(),
                ),
                _buildImpactRow(
                  'Est. Downtime',
                  _impactAnalysis['estimated_downtime'],
                ),
                _buildImpactRow(
                  'Data Migration',
                  _impactAnalysis['data_migration_needed'] ? 'Yes' : 'No',
                ),
                _buildImpactRow('Risk Level', _impactAnalysis['risk_level']),
                SizedBox(height: 1.5.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                    onPressed: _isExecuting ? null : _executeRollback,
                    icon: _isExecuting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.undo, color: Colors.white),
                    label: Text(
                      _isExecuting
                          ? 'Executing Rollback...'
                          : 'Execute Rollback to $_selectedVersion',
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
          ),
          SizedBox(height: 2.h),
          Text(
            'Rollback History',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ..._rollbackHistory.map(
            (rb) => Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${rb['from']} → ${rb['to']}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rb['status'].toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.green,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    rb['reason'],
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 10.sp,
                    ),
                  ),
                  Text(
                    '${rb['executed_by']} • ${rb['timestamp']} • ${rb['affected_users']} users',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 9.sp,
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

  Widget _buildImpactRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 10.sp),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
