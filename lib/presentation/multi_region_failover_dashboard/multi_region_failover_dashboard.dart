import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/failover_history_widget.dart';
import './widgets/region_health_card_widget.dart';
import './widgets/traffic_routing_map_widget.dart';

class MultiRegionFailoverDashboard extends StatefulWidget {
  const MultiRegionFailoverDashboard({super.key});

  @override
  State<MultiRegionFailoverDashboard> createState() =>
      _MultiRegionFailoverDashboardState();
}

class _MultiRegionFailoverDashboardState
    extends State<MultiRegionFailoverDashboard> {
  Timer? _pollTimer;
  bool _isPolling = false;
  DateTime _lastUpdated = DateTime.now();
  final _random = Random();

  // Region health data
  Map<String, Map<String, dynamic>> _regionHealth = {
    'us_east': {
      'health_score': 94.0,
      'latency_ms': 45,
      'active_connections': 12847,
      'cpu_usage': 62.0,
      'mem_usage': 58.0,
    },
    'us_west': {
      'health_score': 88.0,
      'latency_ms': 52,
      'active_connections': 8923,
      'cpu_usage': 71.0,
      'mem_usage': 65.0,
    },
    'eu_west': {
      'health_score': 76.0,
      'latency_ms': 89,
      'active_connections': 6541,
      'cpu_usage': 78.0,
      'mem_usage': 72.0,
    },
    'asia_pacific': {
      'health_score': 91.0,
      'latency_ms': 112,
      'active_connections': 4328,
      'cpu_usage': 55.0,
      'mem_usage': 61.0,
    },
  };

  final List<Map<String, dynamic>> _failoverHistory = [
    {
      'from_region': 'eu_west',
      'to_region': 'us_east',
      'reason': 'Health score dropped below 70%',
      'timestamp': '2026-03-01 14:23',
      'trigger_type': 'automatic',
    },
    {
      'from_region': 'us_west',
      'to_region': 'us_east',
      'reason': 'High latency detected (>200ms)',
      'timestamp': '2026-02-28 09:15',
      'trigger_type': 'automatic',
    },
    {
      'from_region': 'asia_pacific',
      'to_region': 'us_west',
      'reason': 'Manual failover by DevOps',
      'timestamp': '2026-02-27 22:41',
      'trigger_type': 'manual',
    },
  ];

  String _primaryRegion = 'us_east';
  String _optimalRegion = 'us_east';

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollRegionHealth(),
    );
  }

  Future<void> _pollRegionHealth() async {
    if (!mounted) return;
    setState(() => _isPolling = true);

    // Simulate Datadog polling with slight variations
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _regionHealth = {
          'us_east': {
            'health_score': 90.0 + _random.nextDouble() * 8,
            'latency_ms': 40 + _random.nextInt(20),
            'active_connections': 12000 + _random.nextInt(2000),
            'cpu_usage': 55.0 + _random.nextDouble() * 20,
            'mem_usage': 50.0 + _random.nextDouble() * 20,
          },
          'us_west': {
            'health_score': 82.0 + _random.nextDouble() * 12,
            'latency_ms': 45 + _random.nextInt(25),
            'active_connections': 8000 + _random.nextInt(2000),
            'cpu_usage': 60.0 + _random.nextDouble() * 20,
            'mem_usage': 55.0 + _random.nextDouble() * 20,
          },
          'eu_west': {
            'health_score': 70.0 + _random.nextDouble() * 20,
            'latency_ms': 80 + _random.nextInt(30),
            'active_connections': 5500 + _random.nextInt(2000),
            'cpu_usage': 65.0 + _random.nextDouble() * 20,
            'mem_usage': 60.0 + _random.nextDouble() * 20,
          },
          'asia_pacific': {
            'health_score': 85.0 + _random.nextDouble() * 12,
            'latency_ms': 100 + _random.nextInt(30),
            'active_connections': 4000 + _random.nextInt(1000),
            'cpu_usage': 50.0 + _random.nextDouble() * 20,
            'mem_usage': 55.0 + _random.nextDouble() * 20,
          },
        };
        _lastUpdated = DateTime.now();
        _isPolling = false;
        _checkCascadingFailover();
        _selectOptimalRegion();
      });
    }
  }

  void _checkCascadingFailover() {
    final primaryHealth =
        (_regionHealth[_primaryRegion]?['health_score'] ?? 100.0) as double;
    if (primaryHealth < 70) {
      // Cascading check: find healthy secondary
      final regions = ['us_east', 'us_west', 'eu_west', 'asia_pacific'];
      for (final region in regions) {
        if (region != _primaryRegion) {
          final health =
              (_regionHealth[region]?['health_score'] ?? 0.0) as double;
          if (health >= 70) {
            _failoverHistory.insert(0, {
              'from_region': _primaryRegion,
              'to_region': region,
              'reason':
                  'Health score dropped below 70% (${primaryHealth.toStringAsFixed(0)}%)',
              'timestamp':
                  '${DateTime.now().day}/${DateTime.now().month} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              'trigger_type': 'automatic',
            });
            _primaryRegion = region;
            break;
          }
        }
      }
    }
  }

  void _selectOptimalRegion() {
    String best = 'us_east';
    double bestScore = 0;
    _regionHealth.forEach((region, data) {
      final health = (data['health_score'] as double);
      final latency = (data['latency_ms'] as int);
      if (health >= 50) {
        final score = health - (latency / 10);
        if (score > bestScore) {
          bestScore = score;
          best = region;
        }
      }
    });
    _optimalRegion = best;
  }

  void _manualFailover(String fromRegion, String toRegion) {
    setState(() {
      _failoverHistory.insert(0, {
        'from_region': fromRegion,
        'to_region': toRegion,
        'reason': 'Manual failover triggered by admin',
        'timestamp':
            '${DateTime.now().day}/${DateTime.now().month} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'trigger_type': 'manual',
      });
      _primaryRegion = toRegion;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failover: $fromRegion → $toRegion',
          style: GoogleFonts.inter(fontSize: 11.sp),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.public, size: 22),
            SizedBox(width: 2.w),
            Text(
              'Multi-Region Failover',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (_isPolling)
            Padding(
              padding: EdgeInsets.only(right: 3.w),
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _pollRegionHealth,
              tooltip: 'Refresh Now',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(26),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.teal.withAlpha(77)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radar, color: Colors.teal, size: 18),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datadog Monitoring Active — Polling every 30s',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal[800],
                          ),
                        ),
                        Text(
                          'Last updated: ${_lastUpdated.hour}:${_lastUpdated.minute.toString().padLeft(2, '0')}:${_lastUpdated.second.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.3.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(26),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      'Primary: ${_primaryRegion.replaceAll('_', '-').toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            // Region Health Cards
            Text(
              'Region Health',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 1.h,
              childAspectRatio: 1.1,
              children: [
                RegionHealthCardWidget(
                  regionName: 'US East (N. Virginia)',
                  regionCode: 'US-EAST',
                  healthScore:
                      (_regionHealth['us_east']?['health_score'] ?? 94.0)
                          as double,
                  latencyMs:
                      (_regionHealth['us_east']?['latency_ms'] ?? 45) as int,
                  activeConnections:
                      (_regionHealth['us_east']?['active_connections'] ?? 12847)
                          as int,
                  isPrimary: _primaryRegion == 'us_east',
                  onManualFailover: _primaryRegion != 'us_east'
                      ? null
                      : () => _manualFailover('us_east', 'us_west'),
                ),
                RegionHealthCardWidget(
                  regionName: 'US West (Oregon)',
                  regionCode: 'US-WEST',
                  healthScore:
                      (_regionHealth['us_west']?['health_score'] ?? 88.0)
                          as double,
                  latencyMs:
                      (_regionHealth['us_west']?['latency_ms'] ?? 52) as int,
                  activeConnections:
                      (_regionHealth['us_west']?['active_connections'] ?? 8923)
                          as int,
                  isPrimary: _primaryRegion == 'us_west',
                  onManualFailover: _primaryRegion != 'us_west'
                      ? null
                      : () => _manualFailover('us_west', 'us_east'),
                ),
                RegionHealthCardWidget(
                  regionName: 'EU West (Ireland)',
                  regionCode: 'EU-WEST',
                  healthScore:
                      (_regionHealth['eu_west']?['health_score'] ?? 76.0)
                          as double,
                  latencyMs:
                      (_regionHealth['eu_west']?['latency_ms'] ?? 89) as int,
                  activeConnections:
                      (_regionHealth['eu_west']?['active_connections'] ?? 6541)
                          as int,
                  isPrimary: _primaryRegion == 'eu_west',
                  onManualFailover: _primaryRegion != 'eu_west'
                      ? null
                      : () => _manualFailover('eu_west', 'us_east'),
                ),
                RegionHealthCardWidget(
                  regionName: 'Asia Pacific (Singapore)',
                  regionCode: 'APAC',
                  healthScore:
                      (_regionHealth['asia_pacific']?['health_score'] ?? 91.0)
                          as double,
                  latencyMs:
                      (_regionHealth['asia_pacific']?['latency_ms'] ?? 112)
                          as int,
                  activeConnections:
                      (_regionHealth['asia_pacific']?['active_connections'] ??
                              4328)
                          as int,
                  isPrimary: _primaryRegion == 'asia_pacific',
                  onManualFailover: _primaryRegion != 'asia_pacific'
                      ? null
                      : () => _manualFailover('asia_pacific', 'us_east'),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            // Latency Optimization
            Card(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.green),
                        SizedBox(width: 2.w),
                        Text(
                          'Latency-Based Zone Selector',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Optimal region for current request routing:',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.green.withAlpha(77)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            _optimalRegion.replaceAll('_', '-').toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.green[800],
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '— ${(_regionHealth[_optimalRegion]?['latency_ms'] ?? 45)}ms latency, ${(_regionHealth[_optimalRegion]?['health_score'] ?? 90.0).toStringAsFixed(0)}% health',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'All regions by latency:',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    ...(_regionHealth.entries
                        .toList()
                        ..sort(
                          (a, b) => (a.value['latency_ms'] as int).compareTo(
                            b.value['latency_ms'] as int,
                          ),
                        ))
                        .where((e) => (e.value['health_score'] as double) >= 50)
                        .map(
                          (e) => Padding(
                            padding: EdgeInsets.only(bottom: 0.3.h),
                            child: Row(
                              children: [
                                SizedBox(width: 2.w),
                                Text(
                                  e.key.replaceAll('_', '-').toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${e.value['latency_ms']}ms',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  '${(e.value['health_score'] as double).toStringAsFixed(0)}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    color:
                                        (e.value['health_score'] as double) >=
                                            80
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            // Traffic Routing Map
            TrafficRoutingMapWidget(regionHealth: _regionHealth),
            SizedBox(height: 2.h),
            // Failover History
            FailoverHistoryWidget(failoverEvents: _failoverHistory),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}