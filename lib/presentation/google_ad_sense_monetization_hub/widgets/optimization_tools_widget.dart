import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/adsense_service.dart';

class OptimizationToolsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> placementData;
  final VoidCallback onRefresh;

  const OptimizationToolsWidget({
    super.key,
    required this.placementData,
    required this.onRefresh,
  });

  @override
  State<OptimizationToolsWidget> createState() =>
      _OptimizationToolsWidgetState();
}

class _OptimizationToolsWidgetState extends State<OptimizationToolsWidget> {
  final AdSenseService _adSenseService = AdSenseService.instance;
  String _selectedPlacement = 'top-of-feed';
  bool _isRunningTest = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildABTestingSection(),
          SizedBox(height: 2.h),
          _buildFrequencyCappingSection(),
          SizedBox(height: 2.h),
          _buildMediationSection(),
        ],
      ),
    );
  }

  Widget _buildABTestingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.blue, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'A/B Testing',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Test different ad placements to optimize performance',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              initialValue: _selectedPlacement,
              decoration: const InputDecoration(
                labelText: 'Select Placement',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'top-of-feed',
                  child: Text('Top of Feed'),
                ),
                DropdownMenuItem(value: 'mid-feed', child: Text('Mid Feed')),
                DropdownMenuItem(
                  value: 'bottom-of-feed',
                  child: Text('Bottom of Feed'),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedPlacement = value!);
              },
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunningTest ? null : _startABTest,
                icon: Icon(
                  _isRunningTest ? Icons.hourglass_empty : Icons.play_arrow,
                ),
                label: Text(_isRunningTest ? 'Test Running...' : 'Start Test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC629),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyCappingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, color: Colors.orange, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Frequency Capping',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildCapSetting('Max Ads Per Session', '3 ads', Icons.ads_click),
            SizedBox(height: 1.h),
            _buildCapSetting('Interstitial Cooldown', '5 minutes', Icons.timer),
            SizedBox(height: 1.h),
            _buildCapSetting(
              'Banner Refresh Rate',
              '60 seconds',
              Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapSetting(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 13.sp)),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMediationSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.layers, color: Colors.purple, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Ad Mediation',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Fallback ad networks for maximum fill rate',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),
            _buildNetworkRow('Google AdMob', true, 1),
            SizedBox(height: 1.h),
            _buildNetworkRow('Facebook Audience Network', true, 2),
            SizedBox(height: 1.h),
            _buildNetworkRow('Unity Ads', false, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkRow(String name, bool enabled, int priority) {
    return Row(
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: enabled ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              priority.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(name, style: TextStyle(fontSize: 13.sp)),
        ),
        Switch(
          value: enabled,
          onChanged: (value) {},
          activeThumbColor: const Color(0xFFFFC629),
        ),
      ],
    );
  }

  Future<void> _startABTest() async {
    setState(() => _isRunningTest = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isRunningTest = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A/B test started for $_selectedPlacement'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
