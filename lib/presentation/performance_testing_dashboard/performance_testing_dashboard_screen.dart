import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Mobile Performance Testing Dashboard: screen load times, memory, battery impact,
/// network throttling simulation, regression detection alerts.
class PerformanceTestingDashboardScreen extends StatefulWidget {
  const PerformanceTestingDashboardScreen({super.key});

  @override
  State<PerformanceTestingDashboardScreen> createState() =>
      _PerformanceTestingDashboardScreenState();
}

class _PerformanceTestingDashboardScreenState
    extends State<PerformanceTestingDashboardScreen> {
  final List<Map<String, dynamic>> _screenLoadTimes = [
    {'screen': 'Home Feed', 'loadMs': 142, 'baselineMs': 150, 'regression': false},
    {'screen': 'Vote Casting', 'loadMs': 98, 'baselineMs': 100, 'regression': false},
    {'screen': 'Wallet', 'loadMs': 210, 'baselineMs': 180, 'regression': true},
    {'screen': 'Gamification Hub', 'loadMs': 165, 'baselineMs': 170, 'regression': false},
  ];
  int _memoryMb = 124;
  double _batteryImpactPercent = 2.4;
  String _networkProfile = '4G';
  bool _throttling = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() {
        _memoryMb = 120 + (DateTime.now().second % 20);
        _batteryImpactPercent = 2.2 + (DateTime.now().second % 10) / 10;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'PerformanceTestingDashboard',
      onRetry: () => setState(() {}),
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
          title: 'Performance Testing',
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Screen load times', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 2.h),
              ..._screenLoadTimes.map((s) => Card(
                margin: EdgeInsets.only(bottom: 2.h),
                color: (s['regression'] as bool) ? Colors.red.shade50 : null,
                child: ListTile(
                  title: Text(s['screen'] as String),
                  subtitle: Text('${s['loadMs']} ms (baseline ${s['baselineMs']} ms)'),
                  trailing: (s['regression'] as bool)
                      ? Chip(label: Text('REGRESSION', style: TextStyle(fontSize: 10.sp, color: Colors.white)), backgroundColor: Colors.red)
                      : Icon(Icons.check_circle, color: Colors.green, size: 22.sp),
                ),
              )),
              SizedBox(height: 3.h),
              Text('Resource usage', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(child: Card(child: Padding(padding: EdgeInsets.all(4.w), child: Column(children: [Text('Memory', style: TextStyle(fontSize: 11.sp)), Text('$_memoryMb MB', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold))])))),
                  SizedBox(width: 3.w),
                  Expanded(child: Card(child: Padding(padding: EdgeInsets.all(4.w), child: Column(children: [Text('Battery impact', style: TextStyle(fontSize: 11.sp)), Text('${_batteryImpactPercent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold))])))),
                ],
              ),
              SizedBox(height: 3.h),
              Text('Network throttling', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 2.h),
              SegmentedButton<String>(
                segments: [ButtonSegment(value: '4G', label: Text('4G')), ButtonSegment(value: '3G', label: Text('3G')), ButtonSegment(value: 'Slow', label: Text('Slow'))],
                selected: {_networkProfile},
                onSelectionChanged: (v) => setState(() => _networkProfile = v.first),
              ),
              SizedBox(height: 2.h),
              SwitchListTile(
                title: Text('Simulate throttling'),
                value: _throttling,
                onChanged: (v) => setState(() => _throttling = v),
              ),
              SizedBox(height: 3.h),
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amber.shade800, size: 28.sp),
                      SizedBox(width: 3.w),
                      Expanded(child: Text('Regression alerts: Wallet screen load 210ms exceeds baseline 180ms. Review recent changes.', style: TextStyle(fontSize: 12.sp))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
