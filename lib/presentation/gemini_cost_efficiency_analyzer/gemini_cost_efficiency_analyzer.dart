import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/gemini_cost_analyzer_service.dart';

class GeminiCostEfficiencyAnalyzer extends StatefulWidget {
  const GeminiCostEfficiencyAnalyzer({super.key});

  @override
  State<GeminiCostEfficiencyAnalyzer> createState() =>
      _GeminiCostEfficiencyAnalyzerState();
}

class _GeminiCostEfficiencyAnalyzerState
    extends State<GeminiCostEfficiencyAnalyzer>
    with SingleTickerProviderStateMixin {
  final GeminiCostAnalyzerService _analyzerService =
      GeminiCostAnalyzerService.instance;

  Map<String, dynamic> _analysisData = {};
  List<Map<String, dynamic>> _caseReports = [];
  bool _isLoading = true;
  bool _isGeneratingCaseReport = false;
  int _selectedTab = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _loadAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    final data = await _analyzerService.generateCostReport(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
    final reports = await _analyzerService.fetchCaseReports();
    setState(() {
      _analysisData = data['report'] ?? {};
      _caseReports = reports;
      _isLoading = false;
    });
  }

  Future<void> _generateCaseReport() async {
    setState(() => _isGeneratingCaseReport = true);
    final result = await _analyzerService.generateCaseReport(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
    if (!mounted) return;
    setState(() => _isGeneratingCaseReport = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Case report generated! Savings: \$${(result['potential_savings'] as num?)?.toStringAsFixed(0) ?? '0'}/mo (${result['savings_percent']}%). Pending admin approval.',
          ),
          backgroundColor: const Color(0xFFA6E3A1),
          duration: const Duration(seconds: 4),
        ),
      );
      await _loadAnalysis();
      _tabController.animateTo(2); // Switch to Case Reports tab
    }
  }

  Future<void> _approveReport(String reportId) async {
    final result = await _analyzerService.approveCaseReport(
      reportId: reportId,
      approvedBy: 'admin',
    );
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Case report approved. Gemini routing activated.'),
          backgroundColor: Color(0xFFA6E3A1),
        ),
      );
      await _loadAnalysis();
    }
  }

  Future<void> _rejectReport(String reportId) async {
    final result = await _analyzerService.rejectCaseReport(
      reportId: reportId,
      rejectionReason: 'Quality thresholds not met',
    );
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Case report rejected.'),
          backgroundColor: Color(0xFFF38BA8),
        ),
      );
      await _loadAnalysis();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181825),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          'Gemini Cost Analyzer',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadAnalysis,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF89B4FA),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analysis'),
            Tab(text: 'Case Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF89B4FA)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAnalysisTab(),
                _buildCaseReportsTab(),
              ],
            ),
      floatingActionButton: _selectedTab == 2
          ? FloatingActionButton.extended(
              onPressed: _isGeneratingCaseReport ? null : _generateCaseReport,
              backgroundColor: const Color(0xFF89B4FA),
              icon: _isGeneratingCaseReport
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add_chart, color: Color(0xFF1E1E2E)),
              label: Text(
                _isGeneratingCaseReport
                    ? 'Generating...'
                    : 'Generate Case Report',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1E2E),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    final savings = _analysisData['potential_savings'];
    final savingsStr = savings is num
        ? savings.toStringAsFixed(2)
        : (savings?.toString() ?? '0.00');
    final savingsPercent = _analysisData['savings_percent'] ?? '0.0';

    return RefreshIndicator(
      onRefresh: _loadAnalysis,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildSavingsCard(savingsStr, savingsPercent.toString()),
          SizedBox(height: 2.h),
          _buildCostBreakdown(),
          SizedBox(height: 2.h),
          _buildRecommendations(),
          SizedBox(height: 2.h),
          _buildGenerateCaseReportBanner(),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    final taskAnalysis = _analysisData['task_analysis'] as List? ?? [];
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Task-by-Task Analysis',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        if (taskAnalysis.isEmpty)
          Center(
            child: Text(
              'No task data available yet.\nGenerate a cost report to see analysis.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white38),
            ),
          )
        else
          ...taskAnalysis.map(
            (task) => _buildTaskCard(task as Map<String, dynamic>),
          ),
      ],
    );
  }

  Widget _buildCaseReportsTab() {
    return _caseReports.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assessment_outlined,
                  size: 15.w,
                  color: Colors.white24,
                ),
                SizedBox(height: 2.h),
                Text(
                  'No case reports yet',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Tap the button below to generate\nyour first Gemini takeover case report',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white24,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 10.h),
            itemCount: _caseReports.length,
            itemBuilder: (context, index) =>
                _buildCaseReportCard(_caseReports[index]),
          );
  }

  Widget _buildCaseReportCard(Map<String, dynamic> report) {
    final status = report['approval_status'] as String? ?? 'pending';
    final savings =
        (report['potential_savings'] as num?)?.toStringAsFixed(0) ?? '0';
    final savingsPercent =
        (report['savings_percentage'] as num?)?.toStringAsFixed(1) ?? '0.0';
    final title = report['report_title'] as String? ?? 'Case Report';
    final summary = report['executive_summary'] as String? ?? '';
    final complexity = report['implementation_complexity'] as String? ?? 'low';
    final isPending = status == 'pending';

    final statusColor = status == 'approved'
        ? const Color(0xFFA6E3A1)
        : status == 'rejected'
        ? const Color(0xFFF38BA8)
        : const Color(0xFFF9E2AF);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: statusColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildMetricChip('\$$savings/mo saved', const Color(0xFFA6E3A1)),
              SizedBox(width: 2.w),
              _buildMetricChip(
                '$savingsPercent% reduction',
                const Color(0xFF89B4FA),
              ),
              SizedBox(width: 2.w),
              _buildMetricChip(
                complexity.toUpperCase(),
                const Color(0xFFCBA6F7),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.white54,
                height: 1.4,
              ),
            ),
          ],
          if (isPending) ...[
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectReport(report['report_id']),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF38BA8)),
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: const Color(0xFFF38BA8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _approveReport(report['report_id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA6E3A1),
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Approve & Activate',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E2E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGenerateCaseReportBanner() {
    return GestureDetector(
      onTap: () => _tabController.animateTo(2),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1E2E), Color(0xFF252540)],
          ),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFF89B4FA).withAlpha(77)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: const Color(0xFF89B4FA).withAlpha(51),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.assessment,
                color: Color(0xFF89B4FA),
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate Case Report',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Create a detailed Gemini takeover report for admin approval',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white30,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final taskType = task['task_type'] as String? ?? 'unknown';
    final currentCost =
        (task['current_cost'] as num?)?.toStringAsFixed(2) ?? '0';
    final geminiCost = (task['gemini_cost'] as num?)?.toStringAsFixed(2) ?? '0';
    final savings = (task['savings'] as num?)?.toStringAsFixed(2) ?? '0';
    final recommendation = task['recommendation'] as String? ?? 'keep_current';
    final shouldSwitch = recommendation == 'switch';

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: shouldSwitch
              ? const Color(0xFFA6E3A1).withAlpha(77)
              : const Color(0xFF313244),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  taskType.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: shouldSwitch
                      ? const Color(0xFFA6E3A1).withAlpha(51)
                      : const Color(0xFF313244),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  shouldSwitch ? 'SWITCH TO GEMINI' : 'KEEP CURRENT',
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    color: shouldSwitch
                        ? const Color(0xFFA6E3A1)
                        : Colors.white38,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildCostCompare(
                  'Current',
                  '\$$currentCost',
                  Colors.white54,
                ),
              ),
              Expanded(
                child: _buildCostCompare(
                  'Gemini',
                  '\$$geminiCost',
                  const Color(0xFF89B4FA),
                ),
              ),
              Expanded(
                child: _buildCostCompare(
                  'Savings',
                  '\$$savings',
                  const Color(0xFFA6E3A1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostCompare(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.white38),
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
    );
  }

  Widget _buildSavingsCard(String savings, String savingsPercent) {
    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Icon(Icons.savings, size: 48, color: Colors.green.shade400),
            SizedBox(height: 2.h),
            Text(
              'Potential Monthly Savings',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '\$$savings',
              style: GoogleFonts.inter(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade400,
              ),
            ),
            Text(
              '$savingsPercent% cost reduction',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.green.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final breakdown =
        _analysisData['cost_breakdown'] as Map<String, dynamic>? ?? {};

    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Cost Breakdown',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            ...breakdown.entries.map((entry) {
              final cost = (entry.value as num).toStringAsFixed(2);
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '\$$cost',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _analysisData['recommendations'] as List? ?? [];

    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            ...recommendations.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}. ',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF89B4FA),
                        fontSize: 10.sp,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
