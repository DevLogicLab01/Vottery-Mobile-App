import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/content_moderation_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class AnthropicAdvancedContentAnalysisCenter extends StatefulWidget {
  const AnthropicAdvancedContentAnalysisCenter({super.key});

  @override
  State<AnthropicAdvancedContentAnalysisCenter> createState() =>
      _AnthropicAdvancedContentAnalysisCenterState();
}

class _AnthropicAdvancedContentAnalysisCenterState
    extends State<AnthropicAdvancedContentAnalysisCenter>
    with SingleTickerProviderStateMixin {
  final ContentModerationService _moderation = ContentModerationService.instance;
  final _client = SupabaseService.instance.client;

  late TabController _tabController;
  bool _loading = true;
  bool _analyzing = false;

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();

  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _recent = [];
  Map<String, dynamic>? _analysisResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final stats = await _moderation.getModerationStats();
      final logs = await _client
          .from('moderation_log')
          .select('content_id, content_type, is_safe, confidence_score, created_at')
          .order('created_at', ascending: false)
          .limit(20);

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _recent = List<Map<String, dynamic>>.from(logs);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAdvancedAnalysis() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _analyzing = true);
    try {
      final result = await _moderation.moderateContent(
        contentText: _contentController.text.trim(),
        contentType: 'advanced_analysis',
        contentId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      setState(() => _analysisResult = result);
      await _loadDashboard();
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ErrorBoundaryWrapper(
      screenName: 'AnthropicAdvancedContentAnalysisCenter',
      onRetry: _loadDashboard,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Anthropic Advanced Analysis'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Deep Analysis'),
              Tab(text: 'Audit Trail'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboard,
            ),
          ],
        ),
        body: _loading
            ? const SkeletonDashboard()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverview(theme),
                  _buildDeepAnalysis(theme),
                  _buildAuditTrail(theme),
                ],
              ),
      ),
    );
  }

  Widget _buildOverview(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Context-aware moderation metrics',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _metric(theme, 'Flagged', '${_stats['flagged'] ?? 0}', Colors.orange),
              SizedBox(width: 2.w),
              _metric(theme, 'Pending', '${_stats['pending'] ?? 0}', Colors.blue),
              SizedBox(width: 2.w),
              _metric(theme, 'Appeals', '${_stats['appeals'] ?? 0}', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(ThemeData theme, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
            SizedBox(height: 0.5.h),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepAnalysis(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _contentController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Content',
              hintText: 'Paste content for advanced analysis...',
            ),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _contextController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Context',
              hintText: 'Optional creator/audience context',
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _analyzing ? null : _runAdvancedAnalysis,
              icon: _analyzing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology),
              label: Text(_analyzing ? 'Analyzing...' : 'Run Analysis'),
            ),
          ),
          if (_analysisResult != null) ...[
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                _analysisResult.toString(),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditTrail(ThemeData theme) {
    if (_recent.isEmpty) {
      return Center(
        child: Text(
          'No analysis records found',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _recent.length,
      itemBuilder: (context, index) {
        final row = _recent[index];
        final confidence = (row['confidence_score'] as num?)?.toDouble() ?? 0.0;
        return Card(
          margin: EdgeInsets.only(bottom: 1.5.h),
          child: ListTile(
            title: Text('${row['content_type'] ?? 'content'} • ${row['content_id'] ?? 'unknown'}'),
            subtitle: Text('Safe: ${row['is_safe'] == true ? 'Yes' : 'No'} • Confidence: ${confidence.toStringAsFixed(2)}'),
            trailing: Text(
              row['created_at']?.toString()?.split('T').first ?? '',
              style: theme.textTheme.labelSmall,
            ),
          ),
        );
      },
    );
  }
}
