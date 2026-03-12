import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/realtime_dashboard_service.dart';
import '../../../theme/app_theme.dart';

class IntervalConfigurationWidget extends StatefulWidget {
  final RealtimeDashboardService dashboardService;
  final VoidCallback onSave;

  const IntervalConfigurationWidget({
    super.key,
    required this.dashboardService,
    required this.onSave,
  });

  @override
  State<IntervalConfigurationWidget> createState() =>
      _IntervalConfigurationWidgetState();
}

class _IntervalConfigurationWidgetState
    extends State<IntervalConfigurationWidget> {
  final Map<DashboardType, double> _intervals = {};
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    for (final type in DashboardType.values) {
      final interval = widget.dashboardService.config.getInterval(type);
      _intervals[type] = interval.inSeconds.toDouble();
    }
  }

  Future<void> _saveConfiguration() async {
    try {
      for (final entry in _intervals.entries) {
        await widget.dashboardService.configureDashboardRefresh(
          dashboardType: entry.key,
          updateInterval: Duration(seconds: entry.value.toInt()),
        );
      }
      widget.onSave();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving configuration: $e')),
        );
      }
    }
  }

  String _getDashboardName(DashboardType type) {
    return type.name[0].toUpperCase() + type.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.tune, color: AppTheme.primaryLight),
            title: Text(
              'Interval Configuration',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                children: [
                  ...DashboardType.values.map((type) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDashboardName(type),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _intervals[type]!,
                                  min: 5,
                                  max: 300,
                                  divisions: 59,
                                  label: '${_intervals[type]!.toInt()}s',
                                  onChanged: (value) {
                                    setState(() => _intervals[type] = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 15.w,
                                child: Text(
                                  '${_intervals[type]!.toInt()}s',
                                  style: TextStyle(fontSize: 12.sp),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 1.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveConfiguration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Save Configuration',
                        style: TextStyle(fontSize: 14.sp, color: Colors.white),
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
