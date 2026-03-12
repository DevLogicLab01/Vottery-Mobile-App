import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/claude_agent_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

class ClaudeAutonomousActionsHub extends StatefulWidget {
  const ClaudeAutonomousActionsHub({super.key});

  @override
  State<ClaudeAutonomousActionsHub> createState() =>
      _ClaudeAutonomousActionsHubState();
}

class _ClaudeAutonomousActionsHubState extends State<ClaudeAutonomousActionsHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClaudeAgentService _service = ClaudeAgentService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _recentActions = [];
  List<Map<String, dynamic>> _moderationQueue = [];
  Map<String, dynamic> _thresholds = {};
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getAutonomousActions(limit: 50),
        _service.getModerationQueue(status: 'pending'),
        _service.getConfidenceThresholds(),
        _service.getAutonomousActionMetrics(),
      ]);

      setState(() {
        _recentActions = results[0] as List<Map<String, dynamic>>;
        _moderationQueue = results[1] as List<Map<String, dynamic>>;
        _thresholds = results[2] as Map<String, dynamic>;
        _metrics = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ClaudeAutonomousActionsHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Claude Autonomous Actions',
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryLight),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: AppTheme.primaryLight),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : _recentActions.isEmpty
            ? NoDataEmptyState(
                title: 'No Autonomous Actions',
                description: 'Claude AI autonomous actions will appear here.',
                onRefresh: _loadData,
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: Column(
                  children: [
                    _buildMetricsHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRecentActionsTab(),
                          _buildModerationQueueTab(),
                          _buildThresholdsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricsHeader() {
    final totalActions = _metrics['total_actions'] ?? 0;
    final automationRate = (_metrics['automation_rate'] ?? 0.0) * 100;
    final avgConfidence = (_metrics['average_confidence'] ?? 0.0) * 100;

    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricCard(
            'Total Actions',
            totalActions.toString(),
            Icons.bolt,
          ),
          _buildMetricCard(
            'Automation',
            '${automationRate.toStringAsFixed(0)}%',
            Icons.auto_awesome,
          ),
          _buildMetricCard(
            'Avg Confidence',
            '${avgConfidence.toStringAsFixed(0)}%',
            Icons.verified,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 6.w),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(text: 'Recent Actions'),
          Tab(text: 'Moderation Queue'),
          Tab(text: 'Thresholds'),
        ],
      ),
    );
  }

  Widget _buildRecentActionsTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        if (_recentActions.isEmpty)
          _buildEmptyState('No recent actions')
        else
          ..._recentActions.map((action) => _buildActionCard(action)),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    final actionType = action['action_type'] ?? 'unknown';
    final actionTaken = action['action_taken'] ?? 'none';
    final confidence = (action['confidence_score'] as num?)?.toDouble() ?? 0.0;
    final automated = action['automated'] ?? false;
    final reasoning = action['reasoning'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: automated ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  automated ? 'AUTOMATED' : 'MANUAL REVIEW',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  actionType.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Action: ${actionTaken.replaceAll('_', ' ')}',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            reasoning,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(
                'Confidence:',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: LinearProgressIndicator(
                  value: confidence / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryLight,
                  ),
                  minHeight: 0.8.h,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '${confidence.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          if (automated)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: OutlinedButton(
                onPressed: () => _showOverrideDialog(action['id']),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                ),
                child: Text(
                  'Override Action',
                  style: GoogleFonts.inter(fontSize: 11.sp),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModerationQueueTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        if (_moderationQueue.isEmpty)
          _buildEmptyState('No items in moderation queue')
        else
          ..._moderationQueue.map((item) => _buildModerationCard(item)),
      ],
    );
  }

  Widget _buildModerationCard(Map<String, dynamic> item) {
    final contentType = item['content_type'] ?? 'unknown';
    final contentText = item['content_text'] ?? '';
    final confidence = (item['confidence_score'] as num?)?.toDouble() ?? 0.0;
    final violations = List<String>.from(item['flagged_violations'] ?? []);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contentType.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            contentText,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textPrimaryLight,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 1.w,
            children: violations
                .map(
                  (v) => Chip(
                    label: Text(v, style: GoogleFonts.inter(fontSize: 9.sp)),
                    backgroundColor: Colors.red.shade100,
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 1.h),
          Text(
            'Claude Confidence: ${confidence.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _reviewModeration(item['id'], 'approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'Approve',
                    style: GoogleFonts.inter(fontSize: 11.sp),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _reviewModeration(item['id'], 'rejected'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(
                    'Reject',
                    style: GoogleFonts.inter(fontSize: 11.sp),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdsTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Confidence Thresholds',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ..._thresholds.entries.map(
          (entry) => _buildThresholdCard(entry.key, entry.value),
        ),
      ],
    );
  }

  Widget _buildThresholdCard(
    String actionType,
    Map<String, double> thresholds,
  ) {
    final automationThreshold = thresholds['automation_threshold'] ?? 90.0;
    final reviewThreshold = thresholds['review_threshold'] ?? 70.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            actionType.replaceAll('_', ' ').toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Automation Threshold: ${automationThreshold.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Slider(
            value: automationThreshold,
            min: 50,
            max: 100,
            divisions: 50,
            label: automationThreshold.toStringAsFixed(0),
            onChanged: (value) {},
          ),
          SizedBox(height: 1.h),
          Text(
            'Review Threshold: ${reviewThreshold.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Slider(
            value: reviewThreshold,
            min: 50,
            max: 100,
            divisions: 50,
            label: reviewThreshold.toStringAsFixed(0),
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  void _showOverrideDialog(String actionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Override Action',
          style: GoogleFonts.inter(fontSize: 16.sp),
        ),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Override Reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onSubmitted: (reason) async {
            await _service.overrideAutonomousAction(
              actionId: actionId,
              overrideAction: 'manual_override',
              overrideReason: reason,
            );
            Navigator.pop(context);
            _loadData();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewModeration(String itemId, String decision) async {
    await _service.reviewModerationItem(
      itemId: itemId,
      decision: decision,
      feedback: 'Reviewed from mobile app',
    );
    _loadData();
  }
}
