import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/mcq/mcq_claude_optimization_service.dart';
import '../../services/mcq_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

class McqAnalyticsIntelligenceDashboard extends StatefulWidget {
  const McqAnalyticsIntelligenceDashboard({super.key});

  @override
  State<McqAnalyticsIntelligenceDashboard> createState() =>
      _McqAnalyticsIntelligenceDashboardState();
}

class _McqAnalyticsIntelligenceDashboardState
    extends State<McqAnalyticsIntelligenceDashboard> {
  bool _loading = false;
  bool _optimizing = false;
  List<Map<String, dynamic>> _elections = const [];
  String? _selectedElectionId;
  Map<String, dynamic> _analytics = const {};
  String _optimizationNote = '';

  @override
  void initState() {
    super.initState();
    _loadElections();
  }

  Future<void> _loadElections() async {
    setState(() => _loading = true);
    try {
      final rows = await SupabaseService.instance.client
          .from('elections')
          .select('id,title')
          .order('created_at', ascending: false)
          .limit(20);

      final elections = List<Map<String, dynamic>>.from(rows);
      final selected = elections.isNotEmpty ? elections.first['id'] as String : null;

      setState(() {
        _elections = elections;
        _selectedElectionId = selected;
      });

      if (selected != null) {
        await _loadAnalytics(selected);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAnalytics(String electionId) async {
    setState(() => _loading = true);
    try {
      final analytics = await MCQService.instance.getMCQAnalytics(electionId);
      if (!mounted) return;
      setState(() {
        _analytics = analytics;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runClaudeOptimization() async {
    final lowPerforming = _analytics.entries.where((entry) {
      final value = entry.value as Map<String, dynamic>;
      final accuracy = double.tryParse('${value['accuracy_rate'] ?? '0'}') ?? 0.0;
      return accuracy < 60.0;
    }).toList();

    if (lowPerforming.isEmpty) {
      setState(() => _optimizationNote = 'No low-performing questions found.');
      return;
    }

    setState(() => _optimizing = true);
    try {
      final firstQuestion = lowPerforming.first.value as Map<String, dynamic>;
      final suggestion = await MCQClaudeOptimizationService.instance
          .generateOptimizationSuggestions(firstQuestion, accuracyRate: 0.45);

      if (!mounted) return;
      setState(() {
        _optimizationNote =
            'Claude suggestion ready: ${suggestion.improvedQuestionText}';
      });
    } finally {
      if (mounted) setState(() => _optimizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final values =
        _analytics.values.map((e) => e as Map<String, dynamic>).toList(growable: false);
    final totalQuestions = values.length;
    final totalResponses = values.fold<int>(
      0,
      (sum, item) => sum + ((item['total_responses'] as int?) ?? 0),
    );
    final averageAccuracy = totalQuestions == 0
        ? 0.0
        : values.fold<double>(
                0.0,
                (sum, item) =>
                    sum +
                    (double.tryParse('${item['accuracy_rate'] ?? '0'}') ?? 0.0),
              ) /
            totalQuestions;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'MCQ Analytics Intelligence',
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildElectionSelector(),
          SizedBox(height: 2.h),
          _buildSummaryCard(totalQuestions, totalResponses, averageAccuracy),
          SizedBox(height: 2.h),
          _buildQuestionBreakdown(values),
          SizedBox(height: 2.h),
          _buildClaudeCard(),
          if (_loading) ...[
            SizedBox(height: 2.h),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildElectionSelector() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedElectionId,
        decoration: const InputDecoration(
          labelText: 'Election',
          border: OutlineInputBorder(),
        ),
        items: _elections
            .map(
              (e) => DropdownMenuItem<String>(
                value: e['id'] as String,
                child: Text((e['title'] ?? e['id']).toString()),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedElectionId = value);
          _loadAnalytics(value);
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    int totalQuestions,
    int totalResponses,
    double averageAccuracy,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics Summary',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text('Questions: $totalQuestions'),
          Text('Total Responses: $totalResponses'),
          Text('Average Accuracy: ${averageAccuracy.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildQuestionBreakdown(List<Map<String, dynamic>> values) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Per-Question Accuracy',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          if (values.isEmpty)
            Text(
              'No MCQ analytics available yet.',
              style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
            )
          else
            ...values.take(10).map((q) {
              final questionText = (q['question_text'] ?? 'Question').toString();
              final accuracy = (q['accuracy_rate'] ?? '0').toString();
              final responses = (q['total_responses'] ?? 0).toString();
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Text(
                  '- $questionText | Accuracy: $accuracy% | Responses: $responses',
                  style: TextStyle(fontSize: 9.5.sp),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildClaudeCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Claude Optimization',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          ElevatedButton(
            onPressed: _optimizing ? null : _runClaudeOptimization,
            child: Text(_optimizing ? 'Analyzing...' : 'Run Optimization'),
          ),
          if (_optimizationNote.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              _optimizationNote,
              style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
            ),
          ],
        ],
      ),
    );
  }
}
