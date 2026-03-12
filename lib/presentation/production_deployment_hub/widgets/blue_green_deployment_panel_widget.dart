import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class BlueGreenDeploymentPanelWidget extends StatefulWidget {
  const BlueGreenDeploymentPanelWidget({super.key});

  @override
  State<BlueGreenDeploymentPanelWidget> createState() =>
      _BlueGreenDeploymentPanelWidgetState();
}

class _BlueGreenDeploymentPanelWidgetState
    extends State<BlueGreenDeploymentPanelWidget> {
  double _trafficSplit = 100.0; // Blue percentage
  bool _isSwitching = false;

  final Map<String, dynamic> _blueEnv = {
    'status': 'active',
    'version': 'v2.4.1',
    'response_time': '142ms',
    'error_rate': '0.02%',
    'active_users': 12847,
  };

  final Map<String, dynamic> _greenEnv = {
    'status': 'standby',
    'version': 'v2.5.0',
    'response_time': '138ms',
    'error_rate': '0.01%',
    'active_users': 0,
  };

  void _switchTraffic() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Confirm Traffic Switch',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will perform an atomic cutover from Blue (v2.4.1) to Green (v2.5.0). All traffic will be routed to Green environment. Rollback is available.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Switch to Green'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSwitching = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _trafficSplit = 0.0;
          _isSwitching = false;
          _blueEnv['status'] = 'standby';
          _blueEnv['active_users'] = 0;
          _greenEnv['status'] = 'active';
          _greenEnv['active_users'] = 12847;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Traffic switched to Green environment'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildEnvCard(String name, Map<String, dynamic> env, Color color) {
    final isActive = env['status'] == 'active';
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color.withAlpha(128) : Colors.grey.withAlpha(51),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 1.5.w),
                Text(
                  '$name Environment',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withAlpha(51)
                    : Colors.grey.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isActive ? 'ACTIVE — SERVING TRAFFIC' : 'STANDBY — READY',
                style: GoogleFonts.inter(
                  color: isActive ? Colors.green : Colors.grey,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            _buildMetric('Version', env['version']),
            _buildMetric('Response', env['response_time']),
            _buildMetric('Error Rate', env['error_rate']),
            _buildMetric('Active Users', env['active_users'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 10.sp),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blue-Green Deployment',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildEnvCard('Blue', _blueEnv, Colors.blue),
              SizedBox(width: 3.w),
              _buildEnvCard('Green', _greenEnv, Colors.green),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Traffic Routing',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Blue: ${_trafficSplit.toInt()}%',
                      style: GoogleFonts.inter(
                        color: Colors.blue,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Green: ${(100 - _trafficSplit).toInt()}%',
                      style: GoogleFonts.inter(
                        color: Colors.green,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _trafficSplit,
                  min: 0,
                  max: 100,
                  divisions: 10,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.green.withAlpha(128),
                  onChanged: (v) => setState(() => _trafficSplit = v),
                ),
                SizedBox(height: 1.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                    onPressed: _isSwitching ? null : _switchTraffic,
                    icon: _isSwitching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.swap_horiz, color: Colors.white),
                    label: Text(
                      _isSwitching
                          ? 'Switching Traffic...'
                          : 'Switch to Green (Atomic Cutover)',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
