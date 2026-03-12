import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/campaign_optimization_service.dart';
import './widgets/audience_expansion_widget.dart';
import './widgets/automation_rules_widget.dart';
import './widgets/budget_optimizer_widget.dart';
import './widgets/creative_performance_widget.dart';
import './widgets/roi_enhancement_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class CampaignOptimizationDashboard extends StatefulWidget {
  const CampaignOptimizationDashboard({super.key});

  @override
  State<CampaignOptimizationDashboard> createState() =>
      _CampaignOptimizationDashboardState();
}

class _CampaignOptimizationDashboardState
    extends State<CampaignOptimizationDashboard>
    with SingleTickerProviderStateMixin {
  final CampaignOptimizationService _optimizationService =
      CampaignOptimizationService();

  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _audienceSuggestions = [];
  List<Map<String, dynamic>> _creativePerformance = [];
  List<Map<String, dynamic>> _automationRules = [];
  List<Map<String, dynamic>> _roiTracking = [];
  Map<String, dynamic>? _optimizationSummary;

  int _activeCampaigns = 0;
  double _avgRoiImprovement = 0.0;
  int _activeAutomations = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOptimizationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOptimizationData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _optimizationService.getOptimizationRecommendations(status: 'pending'),
        _optimizationService.getAudienceExpansionSuggestions(
          status: 'suggested',
        ),
        _optimizationService.getCreativePerformance(),
        _optimizationService.getAutomationRules(isActive: true),
        _optimizationService.getRoiEnhancementTracking(),
        _optimizationService.getCampaignOptimizationSummary(),
      ]);

      setState(() {
        _recommendations = results[0];
        _audienceSuggestions = results[1];
        _creativePerformance = results[2];
        _automationRules = results[3];
        _roiTracking = results[4];

        final summaryList = results[5];
        if (summaryList.isNotEmpty) {
          _optimizationSummary = summaryList.first;
          _activeCampaigns = summaryList.length;
          _avgRoiImprovement =
              (_optimizationSummary?['avg_roi_improvement'] ?? 0.0).toDouble();
          _activeAutomations =
              (_optimizationSummary?['active_automations'] ?? 0);
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _applyRecommendation(String recommendationId) async {
    try {
      await _optimizationService.applyOptimizationRecommendation(
        recommendationId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Optimization applied successfully')),
      );
      _loadOptimizationData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply optimization: $e')),
      );
    }
  }

  Future<void> _rejectRecommendation(String recommendationId) async {
    try {
      await _optimizationService.rejectOptimizationRecommendation(
        recommendationId,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recommendation rejected')));
      _loadOptimizationData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject recommendation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CampaignOptimizationDashboard',
      onRetry: _loadOptimizationData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            'Campaign Optimization',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: _loadOptimizationData,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(120.h),
            child: Column(
              children: [
                _buildOptimizationStatusHeader(),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(fontSize: 14.sp),
                  tabs: const [
                    Tab(text: 'Budget'),
                    Tab(text: 'Audience'),
                    Tab(text: 'Creative'),
                    Tab(text: 'ROI'),
                    Tab(text: 'Automation'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                    SizedBox(height: 2.h),
                    Text(
                      'Error loading data',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ElevatedButton(
                      onPressed: _loadOptimizationData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  BudgetOptimizerWidget(
                    recommendations: _recommendations
                        .where(
                          (r) =>
                              r['recommendation_type'] == 'budget_reallocation',
                        )
                        .toList(),
                    onApply: _applyRecommendation,
                    onReject: _rejectRecommendation,
                  ),
                  AudienceExpansionWidget(
                    suggestions: _audienceSuggestions,
                    onApply: (id) async {
                      await _optimizationService.applyAudienceExpansion(id);
                      _loadOptimizationData();
                    },
                  ),
                  CreativePerformanceWidget(
                    creatives: _creativePerformance,
                    onMarkWinner: (creativeId, campaignId) async {
                      await _optimizationService.markCreativeAsWinner(
                        creativeId,
                        campaignId,
                      );
                      _loadOptimizationData();
                    },
                  ),
                  RoiEnhancementWidget(enhancements: _roiTracking),
                  AutomationRulesWidget(
                    rules: _automationRules,
                    onToggle: (ruleId, isActive) async {
                      await _optimizationService.toggleAutomationRule(
                        ruleId,
                        isActive,
                      );
                      _loadOptimizationData();
                    },
                    onDelete: (ruleId) async {
                      await _optimizationService.deleteAutomationRule(ruleId);
                      _loadOptimizationData();
                    },
                    onRefresh: _loadOptimizationData,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOptimizationStatusHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
            'Active Campaigns',
            _activeCampaigns.toString(),
            Icons.campaign,
            Colors.blue,
          ),
          _buildStatusItem(
            'Avg ROI Improvement',
            '${_avgRoiImprovement.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.green,
          ),
          _buildStatusItem(
            'Active Automations',
            _activeAutomations.toString(),
            Icons.auto_awesome,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
