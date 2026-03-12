import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class VpEconomyHealthMonitor extends StatefulWidget {
  const VpEconomyHealthMonitor({super.key});

  @override
  State<VpEconomyHealthMonitor> createState() => _VpEconomyHealthMonitorState();
}

class _VpEconomyHealthMonitorState extends State<VpEconomyHealthMonitor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Timer? _refreshTimer;
  StreamSubscription? _realtimeSub;

  // Economy metrics
  double _inflationRate = 0.0;
  double _circulationVelocity = 0.0;
  double _earningSpendingRatio = 1.0;
  List<Map<String, dynamic>> _dailyEarned = [];
  List<Map<String, dynamic>> _dailySpent = [];
  List<Map<String, dynamic>> _zoneRedemptions = [];
  List<Map<String, dynamic>> _activeAlerts = [];

  // Thresholds
  final double _inflationThreshold = 15.0;
  final double _velocityThreshold = 0.5;
  final double _imbalanceThreshold = 30.0;

  SupabaseClient get _client => SupabaseService.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _loadData(),
    );
    _subscribeToTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _realtimeSub?.cancel();
    super.dispose();
  }

  void _subscribeToTransactions() {
    try {
      _realtimeSub = _client
          .from('vp_transactions')
          .stream(primaryKey: ['id'])
          .listen((_) => _loadData());
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadEconomyMetrics(),
        _loadZoneRedemptions(),
        _checkAlerts(),
      ]);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadEconomyMetrics() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final transactions = await _client
          .from('vp_transactions')
          .select('amount, transaction_type, created_at')
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .limit(2000);

      // Aggregate daily earned vs spent
      final dailyMap = <String, Map<String, int>>{};
      int totalEarned = 0, totalSpent = 0;

      for (final t in transactions) {
        final created =
            DateTime.tryParse(t['created_at']?.toString() ?? '') ?? now;
        final dayKey =
            '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
        dailyMap[dayKey] ??= {'earned': 0, 'spent': 0};
        final amount = (t['amount'] as num?)?.toInt() ?? 0;
        if (t['transaction_type'] == 'earn') {
          dailyMap[dayKey]!['earned'] = dailyMap[dayKey]!['earned']! + amount;
          totalEarned += amount;
        } else {
          dailyMap[dayKey]!['spent'] = dailyMap[dayKey]!['spent']! + amount;
          totalSpent += amount;
        }
      }

      final sortedDays = dailyMap.keys.toList()..sort();
      final earned = sortedDays
          .map((d) => {'day': d, 'amount': dailyMap[d]!['earned']!})
          .toList();
      final spent = sortedDays
          .map((d) => {'day': d, 'amount': dailyMap[d]!['spent']!})
          .toList();

      // Calculate metrics
      final totalBalance = await _client
          .from('vp_balance')
          .select('available_vp')
          .limit(1000);
      final totalCirculation = totalBalance.fold<int>(
        0,
        (sum, b) => sum + ((b['available_vp'] as num?)?.toInt() ?? 0),
      );

      final velocity = totalCirculation > 0
          ? (totalEarned / 30) / totalCirculation
          : 0.0;

      // Inflation: compare last 30 days vs previous 30 days
      final sixtyDaysAgo = now.subtract(const Duration(days: 60));
      final prevTransactions = await _client
          .from('vp_transactions')
          .select('amount, transaction_type')
          .gte('created_at', sixtyDaysAgo.toIso8601String())
          .lt('created_at', thirtyDaysAgo.toIso8601String())
          .limit(2000);
      final prevEarned = prevTransactions
          .where((t) => t['transaction_type'] == 'earn')
          .fold<int>(0, (s, t) => s + ((t['amount'] as num?)?.toInt() ?? 0));

      final inflation = prevEarned > 0
          ? ((totalEarned - prevEarned) / prevEarned * 100)
          : 0.0;

      if (mounted) {
        setState(() {
          _dailyEarned = earned;
          _dailySpent = spent;
          _inflationRate = inflation;
          _circulationVelocity = velocity;
          _earningSpendingRatio = totalSpent > 0
              ? totalEarned / totalSpent
              : 1.0;
        });
      }
    } catch (_) {
      // Mock data
      if (mounted) {
        setState(() {
          _inflationRate = 8.3;
          _circulationVelocity = 0.23;
          _earningSpendingRatio = 1.42;
          _dailyEarned = List.generate(
            30,
            (i) => {'day': 'Day ${i + 1}', 'amount': 8000 + i * 200},
          );
          _dailySpent = List.generate(
            30,
            (i) => {'day': 'Day ${i + 1}', 'amount': 5500 + i * 150},
          );
        });
      }
    }
  }

  Future<void> _loadZoneRedemptions() async {
    try {
      final zones = await _client
          .from('vp_zone_redemptions')
          .select()
          .order('redemption_rate', ascending: false);
      if (mounted) {
        setState(() {
          _zoneRedemptions = List<Map<String, dynamic>>.from(zones);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _zoneRedemptions = [
            {
              'zone_name': 'North America',
              'redemption_rate': 68.5,
              'avg_vp_balance': 1250,
              'top_redemption_category': 'Ad-Free',
            },
            {
              'zone_name': 'Europe',
              'redemption_rate': 54.2,
              'avg_vp_balance': 980,
              'top_redemption_category': 'Custom Theme',
            },
            {
              'zone_name': 'Asia Pacific',
              'redemption_rate': 72.1,
              'avg_vp_balance': 1450,
              'top_redemption_category': 'Bonus Votes',
            },
            {
              'zone_name': 'Latin America',
              'redemption_rate': 45.8,
              'avg_vp_balance': 720,
              'top_redemption_category': 'Ad-Free',
            },
            {
              'zone_name': 'Middle East',
              'redemption_rate': 38.3,
              'avg_vp_balance': 650,
              'top_redemption_category': 'Priority Boost',
            },
            {
              'zone_name': 'Africa',
              'redemption_rate': 29.7,
              'avg_vp_balance': 480,
              'top_redemption_category': 'Bonus Votes',
            },
            {
              'zone_name': 'South Asia',
              'redemption_rate': 61.4,
              'avg_vp_balance': 890,
              'top_redemption_category': 'Custom Theme',
            },
            {
              'zone_name': 'Oceania',
              'redemption_rate': 55.9,
              'avg_vp_balance': 1100,
              'top_redemption_category': 'Ad-Free',
            },
          ];
        });
      }
    }
  }

  Future<void> _checkAlerts() async {
    final alerts = <Map<String, dynamic>>[];
    if (_inflationRate.abs() > _inflationThreshold) {
      alerts.add({
        'metric_name': 'Inflation Rate',
        'current_value': '${_inflationRate.toStringAsFixed(1)}%',
        'threshold_value': '${_inflationThreshold.toStringAsFixed(0)}%',
        'deviation': _inflationRate.abs() - _inflationThreshold,
        'severity': _inflationRate.abs() > _inflationThreshold * 2
            ? 'critical'
            : 'warning',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    if (_circulationVelocity > _velocityThreshold) {
      alerts.add({
        'metric_name': 'Circulation Velocity',
        'current_value': _circulationVelocity.toStringAsFixed(3),
        'threshold_value': _velocityThreshold.toStringAsFixed(2),
        'deviation': _circulationVelocity - _velocityThreshold,
        'severity': 'warning',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    if (mounted) setState(() => _activeAlerts = alerts);

    // Log to Supabase if alerts triggered
    if (alerts.isNotEmpty) {
      try {
        for (final alert in alerts) {
          await _client.from('vp_economy_incidents').insert({
            ...alert,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {}
    }
  }

  Color _inflationColor() {
    final abs = _inflationRate.abs();
    if (abs <= 5) return const Color(0xFF4CAF50);
    if (abs <= 15) return const Color(0xFFFFB347);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: CustomAppBar(
        title: 'VP Economy Health',
        variant: CustomAppBarVariant.withBack,
        actions: [
          if (_activeAlerts.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_active,
                    color: Color(0xFFFF6B6B),
                  ),
                  onPressed: () => _tabController.animateTo(3),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_activeAlerts.length}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const ShimmerSkeletonLoader(
              child: SkeletonDashboard(),
            )
          : Column(
              children: [
                // Header metrics
                Container(
                  margin: EdgeInsets.all(3.w),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _inflationColor().withAlpha(200),
                        const Color(0xFF3F3D56),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetric(
                          'Inflation Rate',
                          '${_inflationRate.toStringAsFixed(1)}%',
                          _inflationColor(),
                        ),
                      ),
                      Expanded(
                        child: _buildMetric(
                          'Velocity',
                          _circulationVelocity.toStringAsFixed(3),
                          const Color(0xFF6C63FF),
                        ),
                      ),
                      Expanded(
                        child: _buildMetric(
                          'Earn/Spend',
                          _earningSpendingRatio.toStringAsFixed(2),
                          _earningSpendingRatio > 1
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFF1E1E2E),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: const Color(0xFF6C63FF),
                    labelColor: const Color(0xFF6C63FF),
                    unselectedLabelColor: Colors.white54,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Inflation'),
                      Tab(text: 'Earn vs Spend'),
                      Tab(text: 'Zone Redemptions'),
                      Tab(text: 'Alerts'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInflationTab(),
                      _buildEarnSpendTab(),
                      _buildZoneRedemptionsTab(),
                      _buildAlertsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInflationTab() {
    final color = _inflationColor();
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          Card(
            color: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inflation / Deflation Gauge',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Center(
                    child: SizedBox(
                      height: 18.h,
                      width: 18.h,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: (_inflationRate.abs() / 30).clamp(0.0, 1.0),
                            strokeWidth: 12,
                            backgroundColor: const Color(0xFF2A2A3E),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_inflationRate >= 0 ? '+' : ''}${_inflationRate.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  color: color,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _inflationRate > 0 ? 'Inflation' : 'Deflation',
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildZone('-15%', 'Deflation', const Color(0xFF6C63FF)),
                      _buildZone('±5%', 'Healthy', const Color(0xFF4CAF50)),
                      _buildZone('+15%', 'Inflation', const Color(0xFFFF6B6B)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Card(
            color: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Circulation Velocity',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'VP earned per day / total VP in circulation',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _circulationVelocity.clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFF2A2A3E),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _circulationVelocity > _velocityThreshold
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF6C63FF),
                          ),
                          minHeight: 8,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        _circulationVelocity.toStringAsFixed(3),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnSpendTab() {
    final maxVal = [..._dailyEarned, ..._dailySpent]
        .map((d) => (d['amount'] as num?)?.toDouble() ?? 0)
        .fold(0.0, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Card(
        color: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earning vs Spending Balance',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  _buildLegend('Earned', const Color(0xFF4CAF50)),
                  SizedBox(width: 4.w),
                  _buildLegend('Spent', const Color(0xFFFF6B6B)),
                ],
              ),
              SizedBox(height: 2.h),
              SizedBox(
                height: 25.h,
                child: _dailyEarned.isEmpty
                    ? Center(
                        child: Text(
                          'No data',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 12.sp,
                          ),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (v) =>
                                FlLine(color: Colors.white12, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 10.w,
                                getTitlesWidget: (v, m) => Text(
                                  '${(v / 1000).toStringAsFixed(0)}K',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 9.sp,
                                  ),
                                ),
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          maxY: maxVal * 1.2,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _dailyEarned
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => FlSpot(
                                      e.key.toDouble(),
                                      (e.value['amount'] as num? ?? 0)
                                          .toDouble(),
                                    ),
                                  )
                                  .toList(),
                              isCurved: true,
                              color: const Color(0xFF4CAF50),
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF4CAF50).withAlpha(20),
                              ),
                            ),
                            LineChartBarData(
                              spots: _dailySpent
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => FlSpot(
                                      e.key.toDouble(),
                                      (e.value['amount'] as num? ?? 0)
                                          .toDouble(),
                                    ),
                                  )
                                  .toList(),
                              isCurved: true,
                              color: const Color(0xFFFF6B6B),
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFFFF6B6B).withAlpha(20),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Earn/Spend Ratio: ${_earningSpendingRatio.toStringAsFixed(2)}x',
                style: GoogleFonts.inter(
                  color: _earningSpendingRatio > 1
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF6B6B),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneRedemptionsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          Card(
            color: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zone Redemption Heatmap',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  ..._zoneRedemptions.map((zone) {
                    final rate =
                        (zone['redemption_rate'] as num?)?.toDouble() ?? 0;
                    final color = rate >= 60
                        ? const Color(0xFF4CAF50)
                        : rate >= 40
                        ? const Color(0xFFFFB347)
                        : const Color(0xFFFF6B6B);
                    return Padding(
                      padding: EdgeInsets.only(bottom: 1.5.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  zone['zone_name']?.toString() ?? 'Zone',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              Text(
                                '${rate.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  color: color,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          LinearProgressIndicator(
                            value: rate / 100,
                            backgroundColor: const Color(0xFF2A2A3E),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Card(
            color: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zone Comparison',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFF2A2A3E),
                      ),
                      columnSpacing: 3.w,
                      columns: [
                        DataColumn(
                          label: Text(
                            'Zone',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Redemption',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Avg VP',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Top Category',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ],
                      rows: _zoneRedemptions.map((zone) {
                        final rate =
                            (zone['redemption_rate'] as num?)?.toDouble() ?? 0;
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                zone['zone_name']?.toString() ?? 'Zone',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${rate.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  color: rate >= 60
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFFB347),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${zone['avg_vp_balance'] ?? 0} VP',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                zone['top_redemption_category']?.toString() ??
                                    '-',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          // Threshold configuration
          Card(
            color: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alert Thresholds',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildThresholdRow(
                    'Inflation Threshold',
                    '${_inflationThreshold.toStringAsFixed(0)}%',
                    Icons.trending_up,
                  ),
                  _buildThresholdRow(
                    'Velocity Threshold',
                    _velocityThreshold.toStringAsFixed(2),
                    Icons.speed,
                  ),
                  _buildThresholdRow(
                    'Imbalance Threshold',
                    '${_imbalanceThreshold.toStringAsFixed(0)}%',
                    Icons.balance,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // Active alerts
          if (_activeAlerts.isEmpty)
            Card(
              color: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'All economy metrics within normal range',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4CAF50),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_activeAlerts.map(
              (alert) => Card(
                color: const Color(0xFF1E1E2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin: EdgeInsets.only(bottom: 1.5.h),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: Color(0xFFFF6B6B),
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            alert['metric_name']?.toString() ?? 'Alert',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Current: ${alert['current_value']} | Threshold: ${alert['threshold_value']}',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                      Text(
                        'Deviation: ${(alert['deviation'] as num?)?.toStringAsFixed(1) ?? '0'}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFF6B6B),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 10.sp),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildZone(String label, String name, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          name,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 9.sp),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.sp),
        ),
      ],
    );
  }

  Widget _buildThresholdRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 16),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.sp),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}