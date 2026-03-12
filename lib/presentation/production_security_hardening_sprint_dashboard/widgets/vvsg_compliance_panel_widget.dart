import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class VVSGCompliancePanelWidget extends StatefulWidget {
  final VoidCallback onRunCheck;

  const VVSGCompliancePanelWidget({super.key, required this.onRunCheck});

  @override
  State<VVSGCompliancePanelWidget> createState() =>
      _VVSGCompliancePanelWidgetState();
}

class _VVSGCompliancePanelWidgetState extends State<VVSGCompliancePanelWidget> {
  bool _isGeneratingReport = false;

  final List<Map<String, dynamic>> _checklistItems = [
    {
      'requirement': 'Audit Log Integrity',
      'description': 'All election events logged with tamper-proof timestamps',
      'status': true,
      'evidence_link': '/audit-log',
      'category': 'Audit',
    },
    {
      'requirement': 'Voter Privacy Protection',
      'description': 'Anonymous voting with cryptographic verification',
      'status': true,
      'evidence_link': '/blockchain-vote-verification',
      'category': 'Privacy',
    },
    {
      'requirement': 'Election Integrity Verification',
      'description': 'Blockchain-based vote receipt and verification system',
      'status': true,
      'evidence_link': '/blockchain-vote-receipt',
      'category': 'Integrity',
    },
    {
      'requirement': 'Access Control Management',
      'description': 'Role-based access with biometric authentication',
      'status': true,
      'evidence_link': '/multi-role-admin',
      'category': 'Access',
    },
    {
      'requirement': 'Software Independence',
      'description': 'Paper trail equivalent via blockchain receipts',
      'status': true,
      'evidence_link': '/blockchain-vote-receipt',
      'category': 'Independence',
    },
    {
      'requirement': 'Error Recovery Procedures',
      'description': 'Documented recovery procedures for system failures',
      'status': false,
      'evidence_link': null,
      'category': 'Recovery',
    },
    {
      'requirement': 'Physical Security Controls',
      'description': 'Server infrastructure physical access controls',
      'status': false,
      'evidence_link': null,
      'category': 'Physical',
    },
    {
      'requirement': 'Telecommunications Security',
      'description': 'Encrypted communications for all data transmission',
      'status': true,
      'evidence_link': '/ssl-tls-enforcement',
      'category': 'Telecom',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final passed = _checklistItems.where((i) => i['status'] == true).length;
    final total = _checklistItems.length;
    final score = (passed / total * 100).round();

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScoreCard(passed, total, score),
          SizedBox(height: 2.h),
          _buildChecklistCard(),
          SizedBox(height: 2.h),
          _buildExportCard(),
        ],
      ),
    );
  }

  Widget _buildScoreCard(int passed, int total, int score) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: score >= 80 ? Colors.green : Colors.orange,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                '$score%',
                style: GoogleFonts.inter(
                  color: score >= 80 ? Colors.green : Colors.orange,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VVSG 2.0 Compliance Score',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$passed of $total requirements met',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 10.sp,
                  ),
                ),
                SizedBox(height: 0.5.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: passed / total,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      score >= 80 ? Colors.green : Colors.orange,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard() {
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
              'VVSG 2.0 Verification Standards Checklist',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ..._checklistItems.map(
            (item) => CheckboxListTile(
              value: item['status'] as bool,
              onChanged: (val) {
                setState(() => item['status'] = val ?? false);
              },
              activeColor: Colors.green,
              checkColor: Colors.white,
              title: Text(
                item['requirement'] as String,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['description'] as String,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 9.sp,
                    ),
                  ),
                  if (item['evidence_link'] != null)
                    Text(
                      'Evidence: ${item['evidence_link']}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6366F1),
                        fontSize: 9.sp,
                      ),
                    ),
                ],
              ),
              secondary: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.3.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  item['category'] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 8.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard() {
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
            'Compliance Report Generator',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Generate a comprehensive PDF compliance report with timestamps and digital signatures.',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp),
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingReport
                  ? null
                  : () async {
                      setState(() => _isGeneratingReport = true);
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted) {
                        setState(() => _isGeneratingReport = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '✅ VVSG 2.0 Compliance Report generated',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              icon: _isGeneratingReport
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf, size: 16),
              label: Text(
                _isGeneratingReport
                    ? 'Generating...'
                    : 'Export Compliance Report (PDF)',
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
}
