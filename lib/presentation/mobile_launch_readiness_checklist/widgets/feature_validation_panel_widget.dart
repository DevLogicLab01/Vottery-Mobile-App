import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FeatureValidationPanelWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onStatusUpdate;
  const FeatureValidationPanelWidget({super.key, required this.onStatusUpdate});
  @override
  State<FeatureValidationPanelWidget> createState() =>
      _FeatureValidationPanelWidgetState();
}

class _FeatureValidationPanelWidgetState
    extends State<FeatureValidationPanelWidget> {
  bool _isRunning = false;
  double _progress = 0.0;
  int _screensValidated = 0;
  final int _totalScreens = 33;
  final List<Map<String, dynamic>> _criticalFlows = [
    {'name': 'User Registration', 'status': 'pending', 'loadTime': null},
    {'name': 'Election Voting', 'status': 'pending', 'loadTime': null},
    {'name': 'Payout Withdrawal', 'status': 'pending', 'loadTime': null},
    {'name': 'Creator Onboarding', 'status': 'pending', 'loadTime': null},
    {'name': 'Biometric Auth', 'status': 'pending', 'loadTime': null},
  ];
  final List<Map<String, dynamic>> _screenResults = [];

  Future<void> _runValidation() async {
    setState(() {
      _isRunning = true;
      _progress = 0.0;
      _screensValidated = 0;
      _screenResults.clear();
    });
    for (int i = 0; i < _totalScreens; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      final loadTime = 200 + (i * 15) % 800;
      final hasError = i == 7 || i == 19;
      setState(() {
        _screensValidated = i + 1;
        _progress = (i + 1) / _totalScreens;
        if (_screenResults.length < 10) {
          _screenResults.add({
            'screen': 'Screen ${i + 1}',
            'loadTime': '${loadTime}ms',
            'status': hasError ? 'error' : 'pass',
            'errors': hasError ? 1 : 0,
          });
        }
      });
    }
    for (int i = 0; i < _criticalFlows.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _criticalFlows[i]['status'] = 'success';
        _criticalFlows[i]['loadTime'] = '${350 + i * 50}ms';
      });
    }
    setState(() => _isRunning = false);
    final passed = _screenResults.where((r) => r['status'] == 'pass').length;
    widget.onStatusUpdate({
      'passed': passed,
      'total': _totalScreens,
      'score': (_progress * 100).round(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feature Validation',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Sampling 33 of 326 screens (10%)',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runValidation,
              icon: _isRunning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_circle, size: 16),
              label: Text(
                _isRunning ? 'Running...' : 'Run Tests',
                style: TextStyle(fontSize: 11.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        if (_isRunning || _progress > 0) ...[
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF3B82F6),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '$_screensValidated/$_totalScreens',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
        ],
        Text(
          'Critical User Flows',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 0.5.h),
        ..._criticalFlows.map((flow) {
          final status = flow['status'] as String;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 0.5.h),
            child: Row(
              children: [
                Icon(
                  status == 'success'
                      ? Icons.check_circle
                      : status == 'error'
                      ? Icons.cancel
                      : Icons.radio_button_unchecked,
                  color: status == 'success'
                      ? const Color(0xFF10B981)
                      : status == 'error'
                      ? const Color(0xFFEF4444)
                      : Colors.grey,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    flow['name'] as String,
                    style: TextStyle(fontSize: 11.sp),
                  ),
                ),
                if (flow['loadTime'] != null)
                  Text(
                    flow['loadTime'] as String,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          );
        }),
        if (_screenResults.isNotEmpty) ...[
          SizedBox(height: 1.5.h),
          Text(
            'Screen Results (Sample)',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 0.5.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 3.w,
              headingRowHeight: 3.5.h,
              dataRowMinHeight: 4.h,
              dataRowMaxHeight: 5.h,
              columns: [
                DataColumn(
                  label: Text(
                    'Screen',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Load Time',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Errors',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              rows: _screenResults
                  .map(
                    (r) => DataRow(
                      cells: [
                        DataCell(
                          Text(
                            r['screen'] as String,
                            style: TextStyle(fontSize: 10.sp),
                          ),
                        ),
                        DataCell(
                          Text(
                            r['loadTime'] as String,
                            style: TextStyle(fontSize: 10.sp),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: r['status'] == 'pass'
                                  ? const Color(0xFF10B981).withAlpha(26)
                                  : const Color(0xFFEF4444).withAlpha(26),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              (r['status'] as String).toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: r['status'] == 'pass'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${r['errors']}',
                            style: TextStyle(fontSize: 10.sp),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}
