import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

/// Battery Impact Tab for Mobile Performance Dashboard
class BatteryImpactTabWidget extends StatefulWidget {
  const BatteryImpactTabWidget({super.key});

  @override
  State<BatteryImpactTabWidget> createState() => _BatteryImpactTabWidgetState();
}

class _BatteryImpactTabWidgetState extends State<BatteryImpactTabWidget> {
  Timer? _timer;
  double _currentBatteryLevel = 78.0;
  double _drainRatePerHour = 4.2;
  bool _isMonitoring = false;

  final List<Map<String, dynamic>> _screenBatteryCosts = [
    {
      'screen': 'Jolts Video Feed',
      'avg_drain': 2.8,
      'time_spent': 12.5,
      'total_cost': 35.0,
    },
    {
      'screen': 'Live Streaming Hub',
      'avg_drain': 3.1,
      'time_spent': 8.2,
      'total_cost': 25.4,
    },
    {
      'screen': 'Social Home Feed',
      'avg_drain': 1.2,
      'time_spent': 18.7,
      'total_cost': 22.4,
    },
    {
      'screen': 'Election Creation Studio',
      'avg_drain': 0.9,
      'time_spent': 15.3,
      'total_cost': 13.8,
    },
    {
      'screen': 'Vote Casting',
      'avg_drain': 0.6,
      'time_spent': 9.1,
      'total_cost': 5.5,
    },
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleMonitoring() {
    setState(() => _isMonitoring = !_isMonitoring);
    if (_isMonitoring) {
      _timer = Timer.periodic(const Duration(seconds: 3), (t) {
        if (mounted) {
          setState(() {
            _currentBatteryLevel = (_currentBatteryLevel - 0.1).clamp(0, 100);
            _drainRatePerHour = 3.8 + (DateTime.now().second % 10) * 0.1;
          });
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  Color _getDrainColor(double drain) {
    if (drain > 2.5) return Colors.red;
    if (drain > 1.5) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Battery Impact Analysis',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMonitoring ? Colors.red : Colors.green,
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                ),
                onPressed: _toggleMonitoring,
                icon: Icon(
                  _isMonitoring ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 14,
                ),
                label: Text(
                  _isMonitoring ? 'Stop' : 'Monitor',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _currentBatteryLevel < 20
                          ? Colors.red.withAlpha(128)
                          : Colors.green.withAlpha(77),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _currentBatteryLevel > 50
                            ? Icons.battery_full
                            : _currentBatteryLevel > 20
                            ? Icons.battery_3_bar
                            : Icons.battery_alert,
                        color: _currentBatteryLevel > 50
                            ? Colors.green
                            : _currentBatteryLevel > 20
                            ? Colors.orange
                            : Colors.red,
                        size: 28,
                      ),
                      Text(
                        '${_currentBatteryLevel.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Current Level',
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.trending_down,
                        color: Colors.orange,
                        size: 28,
                      ),
                      Text(
                        '${_drainRatePerHour.toStringAsFixed(1)}%/hr',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Drain Rate',
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Per-Screen Battery Cost (Ranked by Drain)',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ..._screenBatteryCosts.map(
            (item) => Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['screen'],
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item['avg_drain']}%/min',
                        style: GoogleFonts.inter(
                          color: _getDrainColor(item['avg_drain']),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  LinearProgressIndicator(
                    value: item['avg_drain'] / 4.0,
                    backgroundColor: Colors.grey.withAlpha(51),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getDrainColor(item['avg_drain']),
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    'Time: ${item['time_spent']}min • Total cost: ${item['total_cost']}%',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 9.sp,
                    ),
                  ),
                  if (item['avg_drain'] > 2.0) ...[
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['screen'].contains('Video') ||
                                item['screen'].contains('Stream')
                            ? '⚠️ Reduce animation complexity • Optimize video decoding'
                            : '⚠️ Optimize image loading • Reduce background tasks',
                        style: GoogleFonts.inter(
                          color: Colors.orange,
                          fontSize: 8.sp,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
