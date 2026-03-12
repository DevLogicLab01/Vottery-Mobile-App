import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

/// Network Throttling Tab for Mobile Performance Dashboard
class NetworkThrottlingTabWidget extends StatefulWidget {
  const NetworkThrottlingTabWidget({super.key});

  @override
  State<NetworkThrottlingTabWidget> createState() =>
      _NetworkThrottlingTabWidgetState();
}

class _NetworkThrottlingTabWidgetState
    extends State<NetworkThrottlingTabWidget> {
  String _selectedNetwork = 'WiFi';
  bool _isThrottling = false;
  Timer? _throttleTimer;

  final Map<String, Map<String, dynamic>> _networkProfiles = {
    '2G': {'delay_ms': 2000, 'bandwidth': '50 Kbps', 'color': Colors.red},
    '3G': {'delay_ms': 500, 'bandwidth': '1.5 Mbps', 'color': Colors.orange},
    '4G': {'delay_ms': 100, 'bandwidth': '20 Mbps', 'color': Colors.yellow},
    '5G': {'delay_ms': 20, 'bandwidth': '100 Mbps', 'color': Colors.green},
    'WiFi': {'delay_ms': 10, 'bandwidth': '200 Mbps', 'color': Colors.blue},
  };

  final List<Map<String, dynamic>> _performanceComparison = [
    {
      'metric': 'Screen Load Time',
      'wifi': '0.8s',
      '4g': '1.2s',
      '3g': '3.5s',
      '2g': '12.4s',
    },
    {
      'metric': 'API Latency',
      'wifi': '45ms',
      '4g': '120ms',
      '3g': '580ms',
      '2g': '2100ms',
    },
    {
      'metric': 'Image Load Time',
      'wifi': '0.3s',
      '4g': '0.8s',
      '3g': '2.8s',
      '2g': '9.2s',
    },
  ];

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  void _startThrottling() {
    setState(() => _isThrottling = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Network throttling active: $_selectedNetwork (${_networkProfiles[_selectedNetwork]!['delay_ms']}ms delay)',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _stopThrottling() {
    setState(() => _isThrottling = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Network throttling stopped'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _networkProfiles[_selectedNetwork]!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Throttling Simulation',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Network Profile',
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: _networkProfiles.keys.map((network) {
                    final isSelected = _selectedNetwork == network;
                    final color = _networkProfiles[network]!['color'] as Color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedNetwork = network),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withAlpha(51)
                              : Colors.grey.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : Colors.grey.withAlpha(77),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          network,
                          style: GoogleFonts.inter(
                            color: isSelected ? color : Colors.grey,
                            fontSize: 11.sp,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileMetric(
                        'Simulated Delay',
                        '${profile['delay_ms']}ms',
                        profile['color'] as Color,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: _buildProfileMetric(
                        'Bandwidth',
                        profile['bandwidth'],
                        profile['color'] as Color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(vertical: 1.2.h),
                        ),
                        onPressed: _isThrottling ? null : _startThrottling,
                        icon: const Icon(
                          Icons.network_check,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: Text(
                          'Start Throttling',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 1.2.h),
                        ),
                        onPressed: _isThrottling ? _stopThrottling : null,
                        icon: const Icon(
                          Icons.stop,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: Text(
                          'Stop Throttling',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Performance Comparison Table',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFF0F172A),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      'Metric',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'WiFi',
                      style: GoogleFonts.inter(
                        color: Colors.blue,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '4G',
                      style: GoogleFonts.inter(
                        color: Colors.yellow,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '3G',
                      style: GoogleFonts.inter(
                        color: Colors.orange,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '2G',
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
                rows: _performanceComparison
                    .map(
                      (row) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              row['metric'],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              row['wifi'],
                              style: GoogleFonts.inter(
                                color: Colors.blue,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              row['4g'],
                              style: GoogleFonts.inter(
                                color: Colors.yellow,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              row['3g'],
                              style: GoogleFonts.inter(
                                color: Colors.orange,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              row['2g'],
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMetric(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 9.sp),
          ),
        ],
      ),
    );
  }
}
