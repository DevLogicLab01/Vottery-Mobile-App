import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ThresholdConfigurationWidget extends StatefulWidget {
  final Map<String, dynamic> alertConfig;
  final Function(Map<String, dynamic>) onConfigUpdate;

  const ThresholdConfigurationWidget({
    super.key,
    required this.alertConfig,
    required this.onConfigUpdate,
  });

  @override
  State<ThresholdConfigurationWidget> createState() =>
      _ThresholdConfigurationWidgetState();
}

class _ThresholdConfigurationWidgetState
    extends State<ThresholdConfigurationWidget> {
  late TextEditingController _criticalErrorsController;
  late TextEditingController _aiFailuresController;
  late TextEditingController _crashesController;
  late TextEditingController _maxAlertsController;

  @override
  void initState() {
    super.initState();
    _criticalErrorsController = TextEditingController(
      text: '${widget.alertConfig['critical_errors_per_minute'] ?? 10}',
    );
    _aiFailuresController = TextEditingController(
      text: '${widget.alertConfig['ai_service_failures_per_hour'] ?? 5}',
    );
    _crashesController = TextEditingController(
      text: '${widget.alertConfig['crashes_per_day'] ?? 100}',
    );
    _maxAlertsController = TextEditingController(
      text: '${widget.alertConfig['max_alerts_per_error_type_per_hour'] ?? 3}',
    );
  }

  @override
  void dispose() {
    _criticalErrorsController.dispose();
    _aiFailuresController.dispose();
    _crashesController.dispose();
    _maxAlertsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: theme.colorScheme.primary, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Threshold Configuration',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildThresholdField(
              theme,
              'Critical Errors Per Minute',
              _criticalErrorsController,
              'Trigger critical alert when error rate exceeds this value',
              Icons.error,
              Colors.red,
            ),
            SizedBox(height: 2.h),
            _buildThresholdField(
              theme,
              'AI Service Failures Per Hour',
              _aiFailuresController,
              'Trigger high alert when AI service failures exceed this value',
              Icons.smart_toy,
              Colors.orange,
            ),
            SizedBox(height: 2.h),
            _buildThresholdField(
              theme,
              'Crashes Per Day',
              _crashesController,
              'Trigger critical alert when daily crashes exceed this value',
              Icons.bug_report,
              Colors.red,
            ),
            SizedBox(height: 2.h),
            _buildThresholdField(
              theme,
              'Max Alerts Per Error Type Per Hour',
              _maxAlertsController,
              'Prevent alert storms by limiting alerts per error type',
              Icons.notifications_off,
              Colors.blue,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveConfiguration,
                icon: const Icon(Icons.save),
                label: const Text('Save Configuration'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdField(
    ThemeData theme,
    String label,
    TextEditingController controller,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter threshold value',
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.5.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveConfiguration() {
    final config = {
      'critical_errors_per_minute':
          int.tryParse(_criticalErrorsController.text) ?? 10,
      'ai_service_failures_per_hour':
          int.tryParse(_aiFailuresController.text) ?? 5,
      'crashes_per_day': int.tryParse(_crashesController.text) ?? 100,
      'max_alerts_per_error_type_per_hour':
          int.tryParse(_maxAlertsController.text) ?? 3,
    };

    widget.onConfigUpdate(config);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved successfully')),
    );
  }
}
