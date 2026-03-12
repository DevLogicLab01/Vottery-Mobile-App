import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/claude_decision_reasoning_service.dart';

class PolicyInterpretationPanelWidget extends StatefulWidget {
  const PolicyInterpretationPanelWidget({super.key});

  @override
  State<PolicyInterpretationPanelWidget> createState() =>
      _PolicyInterpretationPanelWidgetState();
}

class _PolicyInterpretationPanelWidgetState
    extends State<PolicyInterpretationPanelWidget> {
  final _questionController = TextEditingController();
  bool _loading = false;
  PolicyInterpretationResult? _result;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _interpretPolicy() async {
    if (_questionController.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final result = await ClaudeDecisionReasoningService.interpretPolicy(
      _questionController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Policy Interpretation',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Ask a policy question and Claude will provide an interpretation with citations.',
          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 1.5.h),
        TextField(
          controller: _questionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'e.g. Can users vote in multiple elections simultaneously?',
            hintStyle: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _interpretPolicy,
            icon: _loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.psychology),
            label: Text(
              _loading ? 'Analyzing with Claude...' : 'Analyze with Claude',
              style: GoogleFonts.inter(fontSize: 12.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
            ),
          ),
        ),
        if (_result != null) ...[SizedBox(height: 2.h), _buildResult()],
      ],
    );
  }

  Widget _buildResult() {
    final r = _result!;
    return Card(
      color: Colors.deepPurple.withAlpha(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.deepPurple.withAlpha(51)),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel, color: Colors.deepPurple, size: 18),
                SizedBox(width: 2.w),
                Text(
                  'Policy Interpretation',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    '${r.confidenceScore.toStringAsFixed(0)}% confidence',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Interpretation',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              r.userFriendlyExplanation,
              style: GoogleFonts.inter(fontSize: 11.sp, height: 1.5),
            ),
            if (r.citedPolicies.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(
                'Cited Policies',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              ...r.citedPolicies.map(
                (p) => Padding(
                  padding: EdgeInsets.only(bottom: 0.3.h),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bookmark,
                        size: 14,
                        color: Colors.deepPurple,
                      ),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          p,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (r.edgeCases.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(
                'Edge Cases to Consider',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              ...r.edgeCases.map(
                (e) => Padding(
                  padding: EdgeInsets.only(bottom: 0.3.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 14,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          e,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
