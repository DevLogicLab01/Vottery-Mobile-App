import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api_gateway_service.dart';
import '../../../theme/app_theme.dart';

class FailoverTuningWidget extends StatefulWidget {
  final Map<String, dynamic> configuration;
  final VoidCallback onUpdate;

  const FailoverTuningWidget({
    super.key,
    required this.configuration,
    required this.onUpdate,
  });

  @override
  State<FailoverTuningWidget> createState() => _FailoverTuningWidgetState();
}

class _FailoverTuningWidgetState extends State<FailoverTuningWidget> {
  final APIGatewayService _gatewayService = APIGatewayService();
  bool _isApplying = false;
  bool _isTuning = false;

  Future<void> _runAutomatedTuning() async {
    setState(() => _isTuning = true);
    try {
      await _gatewayService.runAutomatedFailoverTuning();
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Automated tuning completed successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tuning failed: $e')));
      }
    } finally {
      setState(() => _isTuning = false);
    }
  }

  Future<void> _applyRecommendations() async {
    setState(() => _isApplying = true);
    try {
      await _gatewayService.applyFailoverRecommendations();
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recommendations applied successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply recommendations: $e')),
        );
      }
    } finally {
      setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig =
        (widget.configuration['current_configuration']
            as Map<String, dynamic>?) ??
        {};
    final recommendations =
        (widget.configuration['recommended_configuration']
            as Map<String, dynamic>?) ??
        {};
    final expectedImprovement =
        widget.configuration['expected_improvement'] ?? 0.0;
    final tuningHistory =
        (widget.configuration['tuning_history'] as List<dynamic>?) ?? [];

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildCurrentConfiguration(currentConfig),
        SizedBox(height: 3.h),
        _buildRecommendations(recommendations, expectedImprovement),
        SizedBox(height: 3.h),
        _buildTuningHistory(tuningHistory),
        SizedBox(height: 3.h),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildCurrentConfiguration(Map<String, dynamic> config) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Configuration',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (config.isEmpty)
            Text(
              'No configuration data available',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            )
          else
            ...config.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecommendations(
    Map<String, dynamic> recommendations,
    double improvement,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green.withAlpha(77), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.green, size: 18.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'AI Recommendations',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              if (improvement > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(51),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '+${improvement.toStringAsFixed(1)}% improvement',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          if (recommendations.isEmpty)
            Text(
              'No recommendations available',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            )
          else
            ...recommendations.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward, size: 14.sp, color: Colors.green),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTuningHistory(List<dynamic> history) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tuning History',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (history.isEmpty)
            Text(
              'No tuning history available',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            )
          else
            ...history.take(5).map((entry) {
              final timestamp = entry['tuned_at'] ?? '';
              final changes = entry['changes_made'] ?? 'No details';
              final impact = entry['performance_impact'] ?? 0.0;

              return Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 1.w,
                      height: 8.h,
                      color: impact > 0 ? Colors.green : Colors.orange,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            changes,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'Impact: ${impact > 0 ? '+' : ''}${impact.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: impact > 0 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isTuning ? null : _runAutomatedTuning,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
            minimumSize: Size(double.infinity, 6.h),
          ),
          child: _isTuning
              ? SizedBox(
                  height: 2.h,
                  width: 2.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Run Automated Tuning',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white),
                ),
        ),
        SizedBox(height: 2.h),
        OutlinedButton(
          onPressed: _isApplying ? null : _applyRecommendations,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppTheme.primaryLight),
            minimumSize: Size(double.infinity, 6.h),
          ),
          child: _isApplying
              ? SizedBox(
                  height: 2.h,
                  width: 2.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryLight,
                    ),
                  ),
                )
              : Text(
                  'Apply Recommendations',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.primaryLight,
                  ),
                ),
        ),
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
