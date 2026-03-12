import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Real-Time Revenue Optimization Engine (Mobile parity with Web).
/// Dynamic pricing by zone, A/B subscription pricing, auto-pause unprofitable campaigns, margin protection.
class RealTimeRevenueOptimizationScreen extends StatefulWidget {
  const RealTimeRevenueOptimizationScreen({super.key});

  @override
  State<RealTimeRevenueOptimizationScreen> createState() =>
      _RealTimeRevenueOptimizationScreenState();
}

class _RealTimeRevenueOptimizationScreenState
    extends State<RealTimeRevenueOptimizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _zones = [
    {'id': 'z1', 'name': 'Zone 1 - Tier A', 'region': 'US/CA/AU', 'mult': 1.0},
    {'id': 'z2', 'name': 'Zone 2 - Tier B', 'region': 'UK/DE/FR', 'mult': 0.9},
    {'id': 'z3', 'name': 'Zone 3 - Tier C', 'region': 'JP/KR/SG', 'mult': 0.8},
    {'id': 'z4', 'name': 'Zone 4 - Tier D', 'region': 'BR/MX/AR', 'mult': 0.6},
    {'id': 'z5', 'name': 'Zone 5 - Tier E', 'region': 'IN/PK/BD', 'mult': 0.45},
    {'id': 'z6', 'name': 'Zone 6 - Tier F', 'region': 'NG/GH/KE', 'mult': 0.35},
    {'id': 'z7', 'name': 'Zone 7 - Tier G', 'region': 'ID/PH/VN', 'mult': 0.5},
    {'id': 'z8', 'name': 'Zone 8 - Tier H', 'region': 'EG/MA/TN', 'mult': 0.4},
  ];

  static const _plans = [
    {'id': 'basic', 'name': 'Basic', 'base': 4.99, 'vp': '2x'},
    {'id': 'pro', 'name': 'Pro', 'base': 9.99, 'vp': '3x'},
    {'id': 'elite', 'name': 'Elite', 'base': 19.99, 'vp': '5x'},
  ];

  List<Map<String, dynamic>> _campaigns = [
    {'id': 'c1', 'name': 'Summer Voting Boost', 'zone': 'Zone 1', 'revenue': 12400.0, 'cost': 3200.0, 'margin': 74.2, 'paused': false},
    {'id': 'c2', 'name': 'Festival Election Drive', 'zone': 'Zone 3', 'revenue': 4100.0, 'cost': 3900.0, 'margin': 4.9, 'paused': false},
    {'id': 'c3', 'name': 'Tier D Expansion', 'zone': 'Zone 4', 'revenue': 1800.0, 'cost': 2400.0, 'margin': -33.3, 'paused': true},
    {'id': 'c4', 'name': 'Elite Subscriber Push', 'zone': 'Zone 2', 'revenue': 28900.0, 'cost': 6100.0, 'margin': 78.9, 'paused': false},
  ];

  List<Map<String, dynamic>> _abTests = [
    {'name': 'Basic Zone 4 Price Test', 'plan': 'Basic', 'zone': 'Zone 4', 'variantA': '\$2.99', 'variantB': '\$3.49', 'winner': 'B', 'confidence': 94.2, 'status': 'completed'},
    {'name': 'Pro Zone 2 Optimization', 'plan': 'Pro', 'zone': 'Zone 2', 'variantA': '\$8.99', 'variantB': '\$9.49', 'winner': null, 'confidence': 71.3, 'status': 'running'},
  ];

  double _marginThreshold = 15.0;
  bool _autoProtection = true;
  bool _optimizing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleCampaignPause(String id) {
    setState(() {
      final i = _campaigns.indexWhere((c) => c['id'] == id);
      if (i >= 0) _campaigns[i]['paused'] = !(_campaigns[i]['paused'] as bool);
    });
  }

  void _runAutoProtection() {
    setState(() {
      for (var c in _campaigns) {
        final m = c['margin'] as num;
        if (m < _marginThreshold) c['paused'] = true;
      }
    });
  }

  Future<void> _runOptimization() async {
    setState(() => _optimizing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() => _optimizing = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _campaigns.fold<double>(0, (s, c) => s + (c['revenue'] as num).toDouble());
    final totalCost = _campaigns.fold<double>(0, (s, c) => s + (c['cost'] as num).toDouble());
    final overallMargin = totalRevenue > 0 ? ((totalRevenue - totalCost) / totalRevenue * 100) : 0.0;
    final activeCount = _campaigns.where((c) => !(c['paused'] as bool)).length;
    final pausedCount = _campaigns.length - activeCount;

    return ErrorBoundaryWrapper(
      screenName: 'RealTimeRevenueOptimization',
      onRetry: _runOptimization,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(iconName: 'arrow_back', size: 6.w, color: AppTheme.textPrimaryLight),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Revenue Optimization',
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryLight,
            unselectedLabelColor: AppTheme.textSecondaryLight,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Campaigns'),
              Tab(text: 'A/B Tests'),
              Tab(text: 'Zones'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverview(totalRevenue, totalCost, overallMargin, activeCount, pausedCount),
            _buildCampaigns(),
            _buildAbTests(),
            _buildZones(),
          ],
        ),
        floatingActionButton: _autoProtection
            ? null
            : FloatingActionButton.extended(
                onPressed: _runAutoProtection,
                icon: const Icon(Icons.shield),
                label: const Text('Apply Margin Protection'),
              ),
      ),
    );
  }

  Widget _buildOverview(double revenue, double cost, double margin, int active, int paused) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Margin threshold: ${_marginThreshold.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12.sp)),
              Switch(value: _autoProtection, onChanged: (v) => setState(() => _autoProtection = v)),
            ],
          ),
          Text('Auto-pause campaigns below threshold', style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight)),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: _optimizing ? null : _runOptimization,
            icon: _optimizing ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.refresh, size: 18.sp),
            label: Text(_optimizing ? 'Optimizing...' : 'Run Optimization'),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              _kpiCard('Revenue', '\$${revenue.toStringAsFixed(0)}', Colors.green),
              SizedBox(width: 3.w),
              _kpiCard('Cost', '\$${cost.toStringAsFixed(0)}', Colors.orange),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _kpiCard('Margin', '${margin.toStringAsFixed(1)}%', margin >= 15 ? Colors.green : Colors.red),
              SizedBox(width: 3.w),
              _kpiCard('Active', '$active', AppTheme.primaryLight),
            ],
          ),
          SizedBox(height: 2.h),
          _kpiCard('Paused (margin protection)', '$paused', Colors.grey),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight)),
              Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaigns() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _campaigns.length,
      itemBuilder: (context, i) {
        final c = _campaigns[i];
        final paused = c['paused'] as bool;
        final margin = c['margin'] as num;
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: ListTile(
            title: Text(c['name'] as String, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
            subtitle: Text('${c['zone']} · Margin ${margin.toStringAsFixed(1)}%'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('\$${(c['revenue'] as num).toStringAsFixed(0)}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause, color: AppTheme.primaryLight),
                  onPressed: () => _toggleCampaignPause(c['id'] as String),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAbTests() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _abTests.length,
      itemBuilder: (context, i) {
        final t = _abTests[i];
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['name'] as String, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                SizedBox(height: 1.h),
                Text('${t['plan']} · ${t['zone']}', style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight)),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Text('A: ${t['variantA']}', style: TextStyle(fontSize: 12.sp)),
                    SizedBox(width: 4.w),
                    Text('B: ${t['variantB']}', style: TextStyle(fontSize: 12.sp)),
                  ],
                ),
                if (t['winner'] != null) Text('Winner: ${t['winner']}', style: TextStyle(fontSize: 12.sp, color: Colors.green, fontWeight: FontWeight.w600)),
                Text('Confidence: ${t['confidence']}% · ${t['status']}', style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildZones() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _zones.length,
      itemBuilder: (context, i) {
        final z = _zones[i];
        final mult = z['mult'] as num;
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: ListTile(
            title: Text(z['name'] as String, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
            subtitle: Text('${z['region']} · ${(mult * 100).toStringAsFixed(0)}% base'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _plans.map<Widget>((p) {
                final price = (p['base'] as num) * mult;
                return Text('${p['name']}: \$${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 11.sp));
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
