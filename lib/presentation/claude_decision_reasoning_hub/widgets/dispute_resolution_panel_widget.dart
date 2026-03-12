import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/claude_decision_reasoning_service.dart';

class DisputeResolutionPanelWidget extends StatefulWidget {
  const DisputeResolutionPanelWidget({super.key});

  @override
  State<DisputeResolutionPanelWidget> createState() =>
      _DisputeResolutionPanelWidgetState();
}

class _DisputeResolutionPanelWidgetState
    extends State<DisputeResolutionPanelWidget> {
  List<Map<String, dynamic>> _disputes = [];
  bool _loading = true;
  String? _analyzingId;
  DisputeAnalysisResult? _analysisResult;

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    final disputes = await ClaudeDecisionReasoningService.getActiveDisputes();
    if (mounted) {
      setState(() {
        _disputes = disputes;
        _loading = false;
      });
    }
  }

  Future<void> _analyzeDispute(String disputeId) async {
    setState(() {
      _analyzingId = disputeId;
      _analysisResult = null;
    });
    final result = await ClaudeDecisionReasoningService.analyzeDispute(
      disputeId,
    );
    if (mounted) {
      setState(() {
        _analyzingId = null;
        _analysisResult = result;
      });
    }
  }

  Color _resolutionColor(String resolution) {
    switch (resolution) {
      case 'approve':
        return Colors.green;
      case 'partial_refund':
        return Colors.orange;
      case 'deny':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_analysisResult != null) _buildAnalysisResult(),
        Text(
          'Active Disputes (${_disputes.length})',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _disputes.length,
          itemBuilder: (context, index) {
            final d = _disputes[index];
            final isAnalyzing = _analyzingId == d['id'];
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
                                d['user_name'] ??
                                    d['user_id'] ??
                                    'Unknown User',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(26),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  d['type'] ?? 'dispute',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isAnalyzing
                              ? null
                              : () => _analyzeDispute(d['id']),
                          icon: isAnalyzing
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.psychology, size: 16),
                          label: Text(
                            isAnalyzing ? 'Analyzing...' : 'Analyze',
                            style: GoogleFonts.inter(fontSize: 11.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      d['claim'] ?? 'No claim details',
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

  Widget _buildAnalysisResult() {
    final r = _analysisResult!;
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      color: Colors.deepPurple.withAlpha(13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.deepPurple.withAlpha(77)),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.deepPurple),
                SizedBox(width: 2.w),
                Text(
                  'Claude Analysis Result',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _analysisResult = null),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            // Reasoning Chain
            Text(
              'Reasoning Chain',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            ...r.reasoningChain.asMap().entries.map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
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
            // Confidence Scores
            Text(
              'Confidence Scores',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Expanded(
                  child: _buildConfidenceBar(
                    'User',
                    r.userFavorScore,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildConfidenceBar(
                    'Merchant',
                    r.merchantFavorScore,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            // Resolution
            Row(
              children: [
                Text(
                  'Recommendation: ',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: _resolutionColor(
                      r.recommendedResolution,
                    ).withAlpha(26),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: _resolutionColor(r.recommendedResolution),
                    ),
                  ),
                  child: Text(
                    r.recommendedResolution.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: _resolutionColor(r.recommendedResolution),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Appeal Risk: ',
                  style: GoogleFonts.inter(fontSize: 11.sp),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: _riskColor(r.appealRisk).withAlpha(26),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    r.appealRisk.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: _riskColor(r.appealRisk),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            // Action Buttons
            Row(
              children: [
                if (r.userFavorScore > 90)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        'Auto Approve',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else if (r.userFavorScore >= 60)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: Text(
                        'Manual Review',
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
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        'Reject',
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

  Widget _buildConfidenceBar(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${score.toStringAsFixed(0)}%',
          style: GoogleFonts.inter(fontSize: 11.sp),
        ),
        SizedBox(height: 0.3.h),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: color.withAlpha(51),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4.0),
        ),
      ],
    );
  }
}
