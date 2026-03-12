import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/claude_decision_reasoning_service.dart';

class FraudInvestigationPanelWidget extends StatefulWidget {
  const FraudInvestigationPanelWidget({super.key});

  @override
  State<FraudInvestigationPanelWidget> createState() =>
      _FraudInvestigationPanelWidgetState();
}

class _FraudInvestigationPanelWidgetState
    extends State<FraudInvestigationPanelWidget> {
  List<Map<String, dynamic>> _cases = [];
  bool _loading = true;
  String? _investigatingId;
  FraudInvestigationResult? _result;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    final cases =
        await ClaudeDecisionReasoningService.getSuspiciousActivities();
    if (mounted) {
      setState(() {
        _cases = cases;
        _loading = false;
      });
    }
  }

  Future<void> _investigate(String caseId) async {
    setState(() {
      _investigatingId = caseId;
      _result = null;
    });
    final result = await ClaudeDecisionReasoningService.investigateFraud(
      caseId,
    );
    if (mounted) {
      setState(() {
        _investigatingId = null;
        _result = result;
      });
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _probabilityColor(double prob) {
    if (prob > 80) return Colors.red;
    if (prob > 60) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_result != null) _buildInvestigationResult(),
        Text(
          'Suspicious Activities (${_cases.length})',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cases.length,
          itemBuilder: (context, index) {
            final c = _cases[index];
            final isInvestigating = _investigatingId == c['id'];
            return Card(
              margin: EdgeInsets.only(bottom: 1.h),
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Case: ${c['id']}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 0.3.h),
                          Text(
                            'User: ${c['user_id']}',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 0.3.h),
                          Text(
                            'Indicators: ${c['fraud_indicators']}',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: _severityColor(
                              c['severity'] ?? 'low',
                            ).withAlpha(26),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            (c['severity'] ?? 'low').toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              color: _severityColor(c['severity'] ?? 'low'),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        ElevatedButton(
                          onPressed: isInvestigating
                              ? null
                              : () => _investigate(c['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: isInvestigating
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Investigate',
                                  style: GoogleFonts.inter(fontSize: 10.sp),
                                ),
                        ),
                      ],
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

  Widget _buildInvestigationResult() {
    final r = _result!;
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      color: Colors.red.withAlpha(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.red.withAlpha(77)),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: Colors.red),
                SizedBox(width: 2.w),
                Text(
                  'Investigation Result',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _result = null),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            // Investigation Steps
            Text(
              'Investigation Chain',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            ...r.investigationSteps.asMap().entries.map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, size: 16, color: Colors.red[400]),
                    Expanded(
                      child: Text(
                        e.value,
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 1.h),
            // Fraud Probability
            Row(
              children: [
                Text(
                  'Fraud Probability: ',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${r.fraudProbability.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: _probabilityColor(r.fraudProbability),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            LinearProgressIndicator(
              value: r.fraudProbability / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _probabilityColor(r.fraudProbability),
              ),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5.0),
            ),
            SizedBox(height: 1.h),
            // Action Buttons
            Row(
              children: [
                if (r.fraudProbability > 85)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        'Auto Suspend',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else if (r.fraudProbability > 60)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: Text(
                        'Flag for Review',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        'No Action',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
