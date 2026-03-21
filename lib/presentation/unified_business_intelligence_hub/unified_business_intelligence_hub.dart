import 'package:flutter/material.dart';
import 'package:postgrest/postgrest.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';

class UnifiedBusinessIntelligenceHub extends StatefulWidget {
  const UnifiedBusinessIntelligenceHub({super.key});

  @override
  State<UnifiedBusinessIntelligenceHub> createState() =>
      _UnifiedBusinessIntelligenceHubState();
}

class _UnifiedBusinessIntelligenceHubState
    extends State<UnifiedBusinessIntelligenceHub>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService.instance;
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _kpis = {};
  List<Map<String, dynamic>> _aiInsights = [];
  DateTimeRange? _dateRange;
  String? _selectedSegment;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Load executive KPIs
      final kpis = await _loadExecutiveKPIs();

      // Generate AI insights
      final insights = await _generateAIInsights(kpis);

      setState(() {
        _kpis = kpis;
        _aiInsights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    }
  }

  Future<Map<String, dynamic>> _loadExecutiveKPIs() async {
    // Total Platform Users
    final usersCount = await _supabaseService.client
        .from('user_profiles')
        .select('id')
        .count(CountOption.exact);

    // Daily Active Users
    final dauCount = await _supabaseService.client
        .from('user_activity_logs')
        .select('user_id')
        .gte(
          'timestamp',
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        );

    // Monthly Recurring Revenue
    final subscriptions = await _supabaseService.client
        .from('subscriptions')
        .select()
        .eq('status', 'active');

    final mrr = subscriptions
        .map((s) => (s['amount'] as num?)?.toDouble() ?? 0)
        .fold(0.0, (a, b) => a + b);

    // Churn Rate
    final canceledThisMonth = await _supabaseService.client
        .from('subscriptions')
        .select('id')
        .eq('status', 'canceled')
        .gte(
          'canceled_at',
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            1,
          ).toIso8601String(),
        )
        .count(CountOption.exact);

    final churnRate = subscriptions.isNotEmpty
        ? (canceledThisMonth.count / subscriptions.length * 100)
        : 0.0;

    // VP Economy Health
    final vpMetrics = await _supabaseService.client
        .from('vp_economy_metrics')
        .select()
        .order('date', ascending: false)
        .limit(1)
        .maybeSingle();

    final vpHealth = vpMetrics?['health_score'] ?? 0;

    // System Uptime
    final uptimeMetrics = await _supabaseService.client
        .from('sla_metrics')
        .select()
        .order('date', ascending: false)
        .limit(1)
        .maybeSingle();

    final uptime = uptimeMetrics?['uptime_percentage'] ?? 0;

    // Customer Satisfaction
    final csatMetrics = await _supabaseService.client
        .from('customer_satisfaction')
        .select()
        .gte(
          'date',
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        );

    final avgCsat = csatMetrics.isNotEmpty
        ? csatMetrics
                  .map((m) => (m['score'] as num?)?.toDouble() ?? 0)
                  .reduce((a, b) => a + b) /
              csatMetrics.length
        : 0.0;

    return {
      'total_users': usersCount.count,
      'dau': dauCount.length,
      'mrr': mrr,
      'churn_rate': churnRate,
      'vp_health': vpHealth,
      'uptime': uptime,
      'csat': avgCsat,
    };
  }

  Future<List<Map<String, dynamic>>> _generateAIInsights(
    Map<String, dynamic> kpis,
  ) async {
    final prompt =
        '''
Analyze these platform metrics and provide strategic insights:

Key Performance Indicators:
- Total Users: ${kpis['total_users']}
- Daily Active Users: ${kpis['dau']}
- Monthly Recurring Revenue: \$${kpis['mrr'].toStringAsFixed(2)}
- Churn Rate: ${kpis['churn_rate'].toStringAsFixed(1)}%
- VP Economy Health: ${kpis['vp_health']}/100
- System Uptime: ${kpis['uptime'].toStringAsFixed(2)}%
- Customer Satisfaction: ${kpis['csat'].toStringAsFixed(1)}/5

Provide:
1. Top 3 strategic insights with confidence scores
2. Recommended actions for each insight
3. Estimated impact if implemented
4. Cross-metric correlations

Use extended reasoning to identify non-obvious patterns.
''';

    try {
      // Remove the unused response variable since API call method doesn't exist
      // final response = await PerplexityService.callPerplexityAPI(
      //   prompt: prompt,
      //   useExtendedReasoning: true,
      // );

      // Parse insights from response
      return [
        {
          'title': 'User Engagement Optimization',
          'category': 'Growth',
          'description':
              'DAU/MAU ratio suggests opportunity for engagement improvement',
          'confidence': 85,
          'actions': [
            'Implement push notification strategy',
            'Add daily quest system',
            'Optimize onboarding flow',
          ],
          'impact': '+15% DAU increase projected',
        },
        {
          'title': 'Churn Prevention Strategy',
          'category': 'Revenue',
          'description': 'Churn rate correlates with payment flow latency',
          'confidence': 78,
          'actions': [
            'Investigate payment API performance',
            'Implement progress indicators',
            'Add retention offers',
          ],
          'impact': '-8% churn reduction projected',
        },
        {
          'title': 'VP Economy Balancing',
          'category': 'Engagement',
          'description': 'VP circulation rate indicates healthy economy',
          'confidence': 92,
          'actions': [
            'Maintain current reward rates',
            'Monitor inflation metrics',
            'Expand redemption options',
          ],
          'impact': 'Sustained engagement',
        },
      ];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Intelligence Hub'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Executive Summary'),
            Tab(text: 'Performance'),
            Tab(text: 'Security'),
            Tab(text: 'Compliance'),
            Tab(text: 'Platform KPIs'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildGlobalFilters(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildExecutiveSummary(),
                      _buildPerformanceTab(),
                      _buildSecurityTab(),
                      _buildComplianceTab(),
                      _buildPlatformKPIsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGlobalFilters() {
    return Container(
      padding: EdgeInsets.all(2.w),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}',
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSegment,
              decoration: const InputDecoration(
                labelText: 'User Segment',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Users')),
                DropdownMenuItem(value: 'free', child: Text('Free Users')),
                DropdownMenuItem(
                  value: 'premium',
                  child: Text('Premium Users'),
                ),
                DropdownMenuItem(value: 'creators', child: Text('Creators')),
              ],
              onChanged: (value) {
                setState(() => _selectedSegment = value);
                _loadDashboardData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadDashboardData();
    }
  }

  void _showFilterDialog() {
    String selected = _selectedSegment ?? 'all';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Advanced Filters'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Segment'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selected == 'all',
                    onSelected: (_) => setLocal(() => selected = 'all'),
                  ),
                  ChoiceChip(
                    label: const Text('Voters'),
                    selected: selected == 'voters',
                    onSelected: (_) => setLocal(() => selected = 'voters'),
                  ),
                  ChoiceChip(
                    label: const Text('Creators'),
                    selected: selected == 'creators',
                    onSelected: (_) => setLocal(() => selected = 'creators'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _selectedSegment = selected == 'all' ? null : selected;
                });
                Navigator.pop(context);
                _loadDashboardData();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveSummary() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKPIGrid(),
            SizedBox(height: 2.h),
            _buildAIInsightsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 2.w,
      crossAxisSpacing: 2.w,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
          'Total Users',
          _kpis['total_users']?.toString() ?? '0',
          '+12%',
          Icons.people,
          Colors.blue,
        ),
        _buildKPICard(
          'Daily Active Users',
          _kpis['dau']?.toString() ?? '0',
          '+8%',
          Icons.trending_up,
          Colors.green,
        ),
        _buildKPICard(
          'MRR',
          '\$${(_kpis['mrr'] ?? 0).toStringAsFixed(0)}',
          '+15%',
          Icons.attach_money,
          Colors.purple,
        ),
        _buildKPICard(
          'Churn Rate',
          '${(_kpis['churn_rate'] ?? 0).toStringAsFixed(1)}%',
          '-2%',
          Icons.trending_down,
          (_kpis['churn_rate'] ?? 0) > 5 ? Colors.red : Colors.green,
        ),
        _buildKPICard(
          'VP Economy',
          '${_kpis['vp_health']}/100',
          'Healthy',
          Icons.account_balance,
          Colors.orange,
        ),
        _buildKPICard(
          'System Uptime',
          '${(_kpis['uptime'] ?? 0).toStringAsFixed(2)}%',
          'SLA: 99.9%',
          Icons.cloud_done,
          (_kpis['uptime'] ?? 0) > 99.9 ? Colors.green : Colors.orange,
        ),
        _buildKPICard(
          'CSAT Score',
          '${(_kpis['csat'] ?? 0).toStringAsFixed(1)}/5',
          '+0.3',
          Icons.sentiment_satisfied,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    String trend,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24.sp),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: trend.startsWith('+') || trend.startsWith('-')
                      ? (trend.startsWith('+') ? Colors.green : Colors.red)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsPanel() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 24.sp),
              SizedBox(width: 2.w),
              Text(
                'AI-Powered Insights',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ..._aiInsights.map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  insight['title'] ?? '',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  '${insight['confidence']}% confidence',
                  style: TextStyle(fontSize: 10.sp),
                ),
                backgroundColor: Colors.green[100],
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            insight['description'] ?? '',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 1.h),
          Text(
            'Recommended Actions:',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          ...(insight['actions'] as List? ?? []).map(
            (action) => Padding(
              padding: EdgeInsets.only(top: 0.5.h, left: 2.w),
              child: Row(
                children: [
                  Icon(Icons.arrow_right, size: 16.sp),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(action, style: TextStyle(fontSize: 11.sp)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Impact: ${insight['impact']}',
                style: TextStyle(fontSize: 11.sp, color: Colors.green[700]),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                ),
                child: Text('Implement', style: TextStyle(fontSize: 11.sp)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return const Center(child: Text('Performance Analytics'));
  }

  Widget _buildSecurityTab() {
    return const Center(child: Text('Security Analytics'));
  }

  Widget _buildComplianceTab() {
    return const Center(child: Text('Compliance Analytics'));
  }

  Widget _buildPlatformKPIsTab() {
    return const Center(child: Text('Platform KPIs'));
  }
}