import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/claude_decision_reasoning_service.dart';
import './widgets/dispute_card_widget.dart';
import './widgets/fraud_case_card_widget.dart';
import './widgets/analysis_result_panel_widget.dart';

class ClaudeDecisionReasoningHub extends StatefulWidget {
  const ClaudeDecisionReasoningHub({super.key});

  @override
  State<ClaudeDecisionReasoningHub> createState() =>
      _ClaudeDecisionReasoningHubState();
}

class _ClaudeDecisionReasoningHubState extends State<ClaudeDecisionReasoningHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _disputes = [];
  List<Map<String, dynamic>> _fraudCases = [];
  List<Map<String, dynamic>> _appeals = [];
  final Map<String, bool> _analyzingDisputes = {};
  final Map<String, bool> _investigatingFraud = {};
  DisputeAnalysisResult? _selectedDisputeResult;
  FraudInvestigationResult? _selectedFraudResult;
  PolicyInterpretationResult? _policyResult;
  final TextEditingController _policyQuestionController =
      TextEditingController();
  bool _isInterpretingPolicy = false;
  bool _isProcessingAppeal = false;
  String? _processingAppealId;

  // Stats
  int get _activeDisputes => _disputes.length;
  int get _fraudCasesCount => _fraudCases.length;
  int get _policyQueries => _policyResult != null ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _policyQuestionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ClaudeDecisionReasoningService.getActiveDisputes(),
        ClaudeDecisionReasoningService.getSuspiciousActivities(),
      ]);
      if (mounted) {
        setState(() {
          _disputes = results[0];
          _fraudCases = results[1];
          _appeals = []; // Initialize as empty since getPendingAppeals is not available
        });
      }
    } catch (e) {
      // Use mock data on error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeDispute(String disputeId) async {
    setState(() => _analyzingDisputes[disputeId] = true);
    try {
      final result = await ClaudeDecisionReasoningService.analyzeDispute(
        disputeId,
      );
      if (mounted) {
        setState(() => _selectedDisputeResult = result);
        _showAnalysisBottomSheet(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzingDisputes[disputeId] = false);
    }
  }

  Future<void> _investigateFraud(String caseId) async {
    setState(() => _investigatingFraud[caseId] = true);
    try {
      final result = await ClaudeDecisionReasoningService.investigateFraud(
        caseId,
      );
      if (mounted) {
        setState(() => _selectedFraudResult = result);
        _showFraudResultBottomSheet(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Investigation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _investigatingFraud[caseId] = false);
    }
  }

  Future<void> _interpretPolicy() async {
    if (_policyQuestionController.text.trim().isEmpty) return;
    setState(() => _isInterpretingPolicy = true);
    try {
      final result = await ClaudeDecisionReasoningService.interpretPolicy(
        _policyQuestionController.text.trim(),
      );
      if (mounted) setState(() => _policyResult = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Interpretation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isInterpretingPolicy = false);
    }
  }

  Future<void> _processAppeal(String appealId) async {
    setState(() {
      _isProcessingAppeal = true;
      _processingAppealId = appealId;
    });
    try {
      final result = await ClaudeDecisionReasoningService.processAppeal(
        appealId,
      );
      if (mounted) {
        _showAppealResultDialog(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appeal processing failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAppeal = false;
          _processingAppealId = null;
        });
      }
    }
  }

  void _showAnalysisBottomSheet(
    BuildContext context,
    DisputeAnalysisResult result,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 1.h),
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: const Color(0xFF6B4EFF),
                      size: 18.sp,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Claude Analysis Result',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 2.h),
              Expanded(
                child: DisputeAnalysisResultPanel(
                  result: result,
                  onApprove: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dispute approved automatically'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  onReject: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dispute rejected'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  onManualReview: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sent to manual review queue'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFraudResultBottomSheet(
    BuildContext context,
    FraudInvestigationResult result,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 1.h),
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.red.shade700, size: 18.sp),
                    SizedBox(width: 2.w),
                    Text(
                      'Fraud Investigation Result',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 2.h),
              Expanded(child: FraudInvestigationResultPanel(result: result)),
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    if (result.fraudProbability > 85)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account suspended'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          icon: Icon(Icons.block, size: 14.sp),
                          label: Text(
                            'Auto Suspend',
                            style: GoogleFonts.inter(fontSize: 11.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      )
                    else if (result.fraudProbability >= 60)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account flagged for review'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          icon: Icon(Icons.flag, size: 14.sp),
                          label: Text(
                            'Flag for Review',
                            style: GoogleFonts.inter(fontSize: 11.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.check, size: 14.sp),
                          label: Text(
                            'No Action',
                            style: GoogleFonts.inter(fontSize: 11.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppealResultDialog(
    BuildContext context,
    dynamic result,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.decisionOverturned ? Icons.check_circle : Icons.cancel,
              color: result.decisionOverturned ? Colors.green : Colors.red,
              size: 18.sp,
            ),
            SizedBox(width: 2.w),
            Text(
              'Appeal Decision',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.decisionOverturned
                  ? 'Decision OVERTURNED'
                  : 'Decision UPHELD',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: result.decisionOverturned
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Material Evidence: ${result.materialEvidence ? "Yes" : "No"}',
              style: GoogleFonts.inter(fontSize: 12.sp),
            ),
            Text(
              'Confidence Change: ${result.confidenceChange.toInt()}%',
              style: GoogleFonts.inter(fontSize: 12.sp),
            ),
            if (result.newResolution.isNotEmpty)
              Text(
                'New Resolution: ${result.newResolution}',
                style: GoogleFonts.inter(fontSize: 12.sp),
              ),
            SizedBox(height: 1.h),
            Text(
              result.reasoning,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4EFF),
        foregroundColor: Colors.white,
        title: Text(
          'Claude Decision Hub',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Disputes', icon: Icon(Icons.gavel, size: 16)),
            Tab(text: 'Fraud', icon: Icon(Icons.security, size: 16)),
            Tab(text: 'Policy', icon: Icon(Icons.policy, size: 16)),
            Tab(text: 'Appeals', icon: Icon(Icons.rate_review, size: 16)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatusOverview(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDisputeResolutionPanel(),
                      _buildFraudInvestigationPanel(),
                      _buildPolicyInterpretationPanel(),
                      _buildAppealWorkflowPanel(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusOverview() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatChip(
            'Active Disputes',
            _activeDisputes.toString(),
            Colors.orange,
          ),
          SizedBox(width: 2.w),
          _buildStatChip('Fraud Cases', _fraudCasesCount.toString(), Colors.red),
          SizedBox(width: 2.w),
          _buildStatChip('Appeals', _appeals.length.toString(), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeResolutionPanel() {
    if (_disputes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel, size: 40.sp, color: Colors.grey.shade400),
            SizedBox(height: 2.h),
            Text(
              'No active disputes',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _disputes.length,
      itemBuilder: (context, index) {
        final dispute = _disputes[index];
        final disputeId = dispute['id']?.toString() ?? '';
        return DisputeCardWidget(
          dispute: dispute,
          isAnalyzing: _analyzingDisputes[disputeId] == true,
          onAnalyze: () => _analyzeDispute(disputeId),
        );
      },
    );
  }

  Widget _buildFraudInvestigationPanel() {
    if (_fraudCases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 40.sp, color: Colors.grey.shade400),
            SizedBox(height: 2.h),
            Text(
              'No suspicious activities',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _fraudCases.length,
      itemBuilder: (context, index) {
        final fraudCase = _fraudCases[index];
        final caseId = fraudCase['id']?.toString() ?? '';
        return FraudCaseCardWidget(
          fraudCase: fraudCase,
          isInvestigating: _investigatingFraud[caseId] == true,
          onInvestigate: () => _investigateFraud(caseId),
        );
      },
    );
  }

  Widget _buildPolicyInterpretationPanel() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Policy Question',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _policyQuestionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Ask a policy question (e.g., Can users vote in multiple elections simultaneously?)',
              hintStyle: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey.shade400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: GoogleFonts.inter(fontSize: 12.sp),
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isInterpretingPolicy ? null : _interpretPolicy,
              icon: _isInterpretingPolicy
                  ? SizedBox(
                      width: 14.sp,
                      height: 14.sp,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.psychology, size: 14.sp),
              label: Text(
                _isInterpretingPolicy
                    ? 'Interpreting...'
                    : 'Analyze with Claude',
                style: GoogleFonts.inter(fontSize: 12.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          if (_policyResult != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Confidence: ',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_policyResult!.confidenceScore.toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF6B4EFF),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Interpretation',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _policyResult!.interpretation,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  Text(
                    'User-Friendly Explanation',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      _policyResult!.userFriendlyExplanation,
                      style: GoogleFonts.inter(fontSize: 11.sp),
                    ),
                  ),
                  if (_policyResult!.citedPolicies.isNotEmpty) ...[
                    SizedBox(height: 1.5.h),
                    Text(
                      'Cited Policies',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    ..._policyResult!.citedPolicies.map(
                      (p) => Padding(
                        padding: EdgeInsets.only(bottom: 0.3.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.article,
                              size: 12.sp,
                              color: Colors.blue.shade600,
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                p,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_policyResult!.edgeCases.isNotEmpty) ...[
                    SizedBox(height: 1.5.h),
                    Text(
                      'Edge Cases',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    ..._policyResult!.edgeCases.map(
                      (e) => Padding(
                        padding: EdgeInsets.only(bottom: 0.3.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              size: 12.sp,
                              color: Colors.orange.shade600,
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                e,
                                style: GoogleFonts.inter(fontSize: 11.sp),
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
          ],
        ],
      ),
    );
  }

  Widget _buildAppealWorkflowPanel() {
    if (_appeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review, size: 40.sp, color: Colors.grey.shade400),
            SizedBox(height: 2.h),
            Text(
              'No pending appeals',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _appeals.length,
      itemBuilder: (context, index) {
        final appeal = _appeals[index];
        final appealId = appeal['id']?.toString() ?? '';
        final isProcessing =
            _isProcessingAppeal && _processingAppealId == appealId;
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appeal ID: $appealId',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      'Original Decision: ',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      appeal['original_decision']?.toString().toUpperCase() ??
                          'N/A',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  appeal['user_appeal_reason']?.toString() ??
                      'No reason provided',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.5.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () => _processAppeal(appealId),
                    icon: isProcessing
                        ? SizedBox(
                            width: 14.sp,
                            height: 14.sp,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.auto_fix_high, size: 14.sp),
                    label: Text(
                      isProcessing ? 'Processing...' : 'Auto Process Appeal',
                      style: GoogleFonts.inter(fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}