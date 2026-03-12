import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/claude_decision_reasoning_service.dart';

class AppealWorkflowPanelWidget extends StatefulWidget {
  const AppealWorkflowPanelWidget({super.key});

  @override
  State<AppealWorkflowPanelWidget> createState() =>
      _AppealWorkflowPanelWidgetState();
}

class _AppealWorkflowPanelWidgetState extends State<AppealWorkflowPanelWidget> {
  final List<Map<String, dynamic>> _appeals = [
    {
      'id': 'appeal_001',
      'original_decision': 'deny',
      'user_appeal_reason':
          'New evidence: bank statement showing no transaction',
      'status': 'pending',
    },
    {
      'id': 'appeal_002',
      'original_decision': 'partial_refund',
      'user_appeal_reason': 'Full refund warranted due to service failure',
      'status': 'pending',
    },
    {
      'id': 'appeal_003',
      'original_decision': 'deny',
      'user_appeal_reason': 'Account suspension was automated error',
      'status': 'pending',
    },
  ];
  String? _processingId;
  Map<String, dynamic>? _appealResult;

  Future<void> _processAppeal(String appealId) async {
    setState(() {
      _processingId = appealId;
      _appealResult = null;
    });
    final result = await ClaudeDecisionReasoningService.processAppeal(appealId);
    if (mounted) {
      setState(() {
        _processingId = null;
        _appealResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_appealResult != null) _buildAppealResult(),
        Text(
          'Pending Appeals (${_appeals.length})',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _appeals.length,
          itemBuilder: (context, index) {
            final a = _appeals[index];
            final isProcessing = _processingId == a['id'];
            return Card(
              margin: EdgeInsets.only(bottom: 1.h),
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appeal ${a['id']}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 0.3.h),
                              Row(
                                children: [
                                  Text(
                                    'Original: ',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 1.5.w,
                                      vertical: 0.2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withAlpha(26),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Text(
                                      a['original_decision']
                                          .toString()
                                          .toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 9.sp,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () => _processAppeal(a['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                          ),
                          child: isProcessing
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Process',
                                  style: GoogleFonts.inter(fontSize: 11.sp),
                                ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      a['user_appeal_reason'],
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppealResult() {
    final r = _appealResult!;
    final shouldOverturn =
        r['should_overturn'] == 'yes' || r['should_overturn'] == 'partial';
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      color: (shouldOverturn ? Colors.green : Colors.orange).withAlpha(13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: (shouldOverturn ? Colors.green : Colors.orange).withAlpha(77),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  shouldOverturn ? Icons.check_circle : Icons.cancel,
                  color: shouldOverturn ? Colors.green : Colors.orange,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Appeal Decision',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: shouldOverturn ? Colors.green : Colors.orange,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _appealResult = null),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            _buildResultRow(
              'Material Evidence',
              r['is_new_evidence_material'] == true ? 'Yes' : 'No',
              r['is_new_evidence_material'] == true ? Colors.green : Colors.red,
            ),
            _buildResultRow(
              'Confidence Change',
              '+${r['confidence_change'] ?? 0}%',
              Colors.blue,
            ),
            _buildResultRow(
              'Decision',
              r['should_overturn'].toString().toUpperCase(),
              shouldOverturn ? Colors.green : Colors.orange,
            ),
            if (r['new_resolution'] != null)
              _buildResultRow(
                'New Resolution',
                r['new_resolution'].toString(),
                Colors.teal,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
