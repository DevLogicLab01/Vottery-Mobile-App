import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/creator_churn_prediction_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/at_risk_creator_card_widget.dart';
import './widgets/churn_analytics_panel_widget.dart';
import './widgets/risk_assessment_matrix_widget.dart';

class CreatorChurnPredictionDashboard extends StatefulWidget {
  const CreatorChurnPredictionDashboard({super.key});

  @override
  State<CreatorChurnPredictionDashboard> createState() =>
      _CreatorChurnPredictionDashboardState();
}

class _CreatorChurnPredictionDashboardState
    extends State<CreatorChurnPredictionDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CreatorChurnPredictionService _service =
      CreatorChurnPredictionService.instance;

  List<ChurnPrediction> _predictions = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String _selectedRiskFilter = 'all';
  String _selectedTimeframeFilter = 'all';

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
        _service.fetchAtRiskCreators(
          riskLevelFilter: _selectedRiskFilter == 'all'
              ? null
              : _selectedRiskFilter,
        ),
        _service.fetchChurnAnalytics(),
      ]);
      if (mounted) {
        setState(() {
          _predictions = results[0] as List<ChurnPrediction>;
          _analytics = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ChurnPrediction> get _filteredPredictions {
    var filtered = _predictions;
    if (_selectedRiskFilter != 'all') {
      filtered = filtered
          .where((p) => p.riskLevel == _selectedRiskFilter)
          .toList();
    }
    if (_selectedTimeframeFilter != 'all') {
      final days = int.tryParse(_selectedTimeframeFilter) ?? 30;
      filtered = filtered.where((p) => p.churnTimeframeDays <= days).toList();
    }
    return filtered;
  }

  Future<void> _sendRetentionCampaign(ChurnPrediction prediction) async {
    final success = await _service.triggerRetentionWorkflow(
      predictionId: prediction.predictionId,
      creatorUserId: prediction.creatorUserId,
      creatorName: prediction.creatorName,
      phoneNumber: null,
      email: null,
      churnTimeframeDays: prediction.churnTimeframeDays,
      tier: prediction.tier,
      interventions: prediction.recommendedInterventions,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Retention campaign sent to ${prediction.creatorName}'
                : 'Campaign queued for ${prediction.creatorName}',
          ),
          backgroundColor: success
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B),
          duration: const Duration(seconds: 3),
        ),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: CustomAppBar(
        title: 'Churn Prediction',
        variant: CustomAppBarVariant.withBack,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF374151)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusOverview(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAtRiskCreatorsTab(),
                      _buildAnalyticsTab(),
                      _buildRiskMatrixTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverview() {
    final totalAtRisk = _analytics['total_at_risk'] as int? ?? 0;
    final criticalCount = _analytics['critical_count'] as int? ?? 0;
    final responseRate = ((_analytics['response_rate'] as double? ?? 0.0) * 100)
        .toStringAsFixed(0);
    final savedCount = _analytics['saved_creators_count'] as int? ?? 0;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: [
          _OverviewChip(
            label: 'At Risk',
            value: '$totalAtRisk',
            color: const Color(0xFFF97316),
            icon: Icons.warning_amber_outlined,
          ),
          SizedBox(width: 2.w),
          _OverviewChip(
            label: 'Critical',
            value: '$criticalCount',
            color: const Color(0xFFEF4444),
            icon: Icons.emergency_outlined,
          ),
          SizedBox(width: 2.w),
          _OverviewChip(
            label: 'Success Rate',
            value: '$responseRate%',
            color: const Color(0xFF10B981),
            icon: Icons.check_circle_outline,
          ),
          SizedBox(width: 2.w),
          _OverviewChip(
            label: 'Saved',
            value: '$savedCount',
            color: const Color(0xFF3B82F6),
            icon: Icons.people_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF3B82F6),
        unselectedLabelColor: const Color(0xFF9CA3AF),
        indicatorColor: const Color(0xFF3B82F6),
        indicatorWeight: 2.5,
        labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'At-Risk Creators'),
          Tab(text: 'Analytics'),
          Tab(text: 'Risk Matrix'),
        ],
      ),
    );
  }

  Widget _buildAtRiskCreatorsTab() {
    final filtered = _filteredPredictions;

    return Column(
      children: [
        _buildTimeframeFilter(),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final prediction = filtered[index];
                      return AtRiskCreatorCardWidget(
                        prediction: prediction,
                        onSendSms: () => _sendRetentionCampaign(prediction),
                        onSendEmail: () => _sendRetentionCampaign(prediction),
                        onViewProfile: () => _showCreatorDetails(prediction),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTimeframeFilter() {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': '7 Days', 'value': '7'},
      {'label': '14 Days', 'value': '14'},
      {'label': '30 Days', 'value': '30'},
    ];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedTimeframeFilter == f['value'];
            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTimeframeFilter = f['value']!);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    f['label']!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: ChurnAnalyticsPanelWidget(analytics: _analytics),
      ),
    );
  }

  Widget _buildRiskMatrixTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: RiskAssessmentMatrixWidget(
          predictions: _predictions,
          selectedRiskFilter: _selectedRiskFilter,
          onFilterChanged: (filter) {
            setState(() => _selectedRiskFilter = filter);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: const Color(0xFF10B981),
          ),
          SizedBox(height: 2.h),
          Text(
            'No at-risk creators',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'All creators are engaged and active',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  void _showCreatorDetails(ChurnPrediction prediction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatorDetailsSheet(prediction: prediction),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _OverviewChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.5.w),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(height: 0.3.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 8.sp, color: const Color(0xFF9CA3AF)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorDetailsSheet extends StatelessWidget {
  final ChurnPrediction prediction;

  const _CreatorDetailsSheet({required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            prediction.creatorName,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Churn Risk: ${(prediction.churnProbability * 100).toStringAsFixed(0)}% — ${prediction.riskLevel.toUpperCase()}',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF6B7280)),
          ),
          SizedBox(height: 2.h),
          Text(
            'Recommended Interventions',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          SizedBox(height: 1.h),
          ...prediction.recommendedInterventions.map((intervention) {
            final type = intervention['type'] as String? ?? '';
            final message = intervention['message'] as String? ?? '';
            final effectiveness =
                ((intervention['effectiveness'] as double? ?? 0.0) * 100)
                    .toStringAsFixed(0);
            return Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Icon(
                    type == 'sms'
                        ? Icons.sms_outlined
                        : type == 'email'
                        ? Icons.email_outlined
                        : Icons.notifications_outlined,
                    size: 18,
                    color: const Color(0xFF3B82F6),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF374151),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Effectiveness: $effectiveness%',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                'Close',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}