import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AlertConfigurationPanelWidget extends StatefulWidget {
  final Map<String, dynamic> thresholds;
  final List<Map<String, dynamic>> activeAlerts;
  final Function(Map<String, dynamic>) onThresholdSaved;

  const AlertConfigurationPanelWidget({
    super.key,
    required this.thresholds,
    required this.activeAlerts,
    required this.onThresholdSaved,
  });

  @override
  State<AlertConfigurationPanelWidget> createState() =>
      _AlertConfigurationPanelWidgetState();
}

class _AlertConfigurationPanelWidgetState
    extends State<AlertConfigurationPanelWidget> {
  late TextEditingController _screenLoadCtrl;
  late TextEditingController _memoryCtrl;
  late TextEditingController _apiP95Ctrl;
  late TextEditingController _crashRateCtrl;

  @override
  void initState() {
    super.initState();
    _screenLoadCtrl = TextEditingController(
      text: widget.thresholds['screen_load_threshold']?.toString() ?? '2000',
    );
    _memoryCtrl = TextEditingController(
      text: widget.thresholds['memory_threshold']?.toString() ?? '500',
    );
    _apiP95Ctrl = TextEditingController(
      text: widget.thresholds['api_p95_threshold']?.toString() ?? '3000',
    );
    _crashRateCtrl = TextEditingController(
      text: widget.thresholds['crash_rate_threshold']?.toString() ?? '1',
    );
  }

  @override
  void dispose() {
    _screenLoadCtrl.dispose();
    _memoryCtrl.dispose();
    _apiP95Ctrl.dispose();
    _crashRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFF6C63FF), size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Alert Configuration',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildThresholdInput(
              'Screen Load Threshold (ms)',
              _screenLoadCtrl,
              'ms',
            ),
            SizedBox(height: 1.5.h),
            _buildThresholdInput('Memory Threshold (MB)', _memoryCtrl, 'MB'),
            SizedBox(height: 1.5.h),
            _buildThresholdInput('API P95 Threshold (ms)', _apiP95Ctrl, 'ms'),
            SizedBox(height: 1.5.h),
            _buildThresholdInput(
              'Crash Rate Threshold (%)',
              _crashRateCtrl,
              '%',
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onThresholdSaved({
                    'screen_load_threshold':
                        int.tryParse(_screenLoadCtrl.text) ?? 2000,
                    'memory_threshold': int.tryParse(_memoryCtrl.text) ?? 500,
                    'api_p95_threshold': int.tryParse(_apiP95Ctrl.text) ?? 3000,
                    'crash_rate_threshold':
                        double.tryParse(_crashRateCtrl.text) ?? 1.0,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Save Thresholds',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (widget.activeAlerts.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                'Active Alerts (${widget.activeAlerts.length})',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF6B6B),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              ...widget.activeAlerts
                  .take(5)
                  .map(
                    (alert) => Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withAlpha(15),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: const Color(0xFFFF6B6B).withAlpha(50),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber,
                              color: Color(0xFFFF6B6B),
                              size: 16,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert['metric_name']?.toString() ??
                                        'Unknown',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Current: ${alert['current_value']} | Threshold: ${alert['threshold_value']}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white54,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdInput(
    String label,
    TextEditingController ctrl,
    String unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.sp),
        ),
        SizedBox(height: 0.5.h),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 12.sp),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2A2A3E),
            suffixText: unit,
            suffixStyle: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 11.sp,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.h,
            ),
          ),
        ),
      ],
    );
  }
}
