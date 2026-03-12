import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class InflationControlsWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const InflationControlsWidget({super.key, required this.onRefresh});

  @override
  State<InflationControlsWidget> createState() =>
      _InflationControlsWidgetState();
}

class _InflationControlsWidgetState extends State<InflationControlsWidget> {
  double _inflationModifier = 0.0;
  bool _isApplying = false;

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
                iconName: 'trending_up',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Inflation Controls',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Percentage Modifier Affecting All VP Transactions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Modifier',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_inflationModifier > 0 ? "+" : ""}${_inflationModifier.toStringAsFixed(1)}%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _inflationModifier > 0
                      ? Colors.red
                      : _inflationModifier < 0
                      ? Colors.green
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Slider(
            value: _inflationModifier,
            min: -50.0,
            max: 50.0,
            divisions: 100,
            label: '${_inflationModifier.toStringAsFixed(1)}%',
            onChanged: (value) => setState(() => _inflationModifier = value),
          ),
          SizedBox(height: 2.h),
          _buildEconomicModelingPreview(theme),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isApplying ? null : _applyInflationModifier,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              child: _isApplying
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      'Apply Inflation Modifier',
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

  Widget _buildEconomicModelingPreview(ThemeData theme) {
    final impact = _inflationModifier > 0
        ? 'Inflationary: VP value decreases, users earn more'
        : _inflationModifier < 0
        ? 'Deflationary: VP value increases, users earn less'
        : 'Neutral: No change to VP economy';

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
            'Economic Modeling',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(impact, style: theme.textTheme.bodySmall),
          Text(
            'Engagement correlation: ${_inflationModifier.abs() > 20 ? "High impact" : "Low impact"}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _applyInflationModifier() async {
    setState(() => _isApplying = true);

    // TODO: Implement API call to update inflation modifier
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isApplying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inflation modifier applied successfully'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onRefresh();
    }
  }
}
