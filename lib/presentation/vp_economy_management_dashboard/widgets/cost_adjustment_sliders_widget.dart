import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CostAdjustmentSlidersWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const CostAdjustmentSlidersWidget({super.key, required this.onRefresh});

  @override
  State<CostAdjustmentSlidersWidget> createState() =>
      _CostAdjustmentSlidersWidgetState();
}

class _CostAdjustmentSlidersWidgetState
    extends State<CostAdjustmentSlidersWidget> {
  double _votingVP = 10.0;
  double _socialVP = 5.0;
  double _challengeMinVP = 50.0;
  double _predictionMaxVP = 1000.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'tune',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Dynamic VP Cost Adjustment',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSlider(
            theme,
            'Voting Reward',
            _votingVP,
            5.0,
            50.0,
            (value) => setState(() => _votingVP = value),
          ),
          _buildSlider(
            theme,
            'Social Interaction Reward',
            _socialVP,
            1.0,
            20.0,
            (value) => setState(() => _socialVP = value),
          ),
          _buildSlider(
            theme,
            'Challenge Min Reward',
            _challengeMinVP,
            10.0,
            200.0,
            (value) => setState(() => _challengeMinVP = value),
          ),
          _buildSlider(
            theme,
            'Prediction Max Reward',
            _predictionMaxVP,
            500.0,
            5000.0,
            (value) => setState(() => _predictionMaxVP = value),
          ),
          SizedBox(height: 2.h),
          _buildImpactPreview(theme),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              child: Text(
                'Apply Changes',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    ThemeData theme,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${value.toInt()} VP',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 5).toInt(),
            label: '${value.toInt()} VP',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactPreview(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Real-Time Impact Preview',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Estimated daily VP distribution: ${(_votingVP * 100 + _socialVP * 200 + _challengeMinVP * 10).toInt()} VP',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'User behavior prediction: ${_votingVP > 15 ? "High engagement" : "Moderate engagement"}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _applyChanges() {
    // TODO: Implement API call to update VP costs in database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('VP cost adjustments applied successfully'),
        backgroundColor: Colors.green,
      ),
    );
    widget.onRefresh();
  }
}
