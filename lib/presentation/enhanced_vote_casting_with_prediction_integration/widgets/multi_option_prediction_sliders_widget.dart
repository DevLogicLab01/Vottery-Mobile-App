import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Multi-option prediction sliders for ranked choice voting with auto-normalize
class MultiOptionPredictionSlidersWidget extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final Map<String, double> predictions;
  final Function(Map<String, double>) onPredictionChanged;

  const MultiOptionPredictionSlidersWidget({
    super.key,
    required this.options,
    required this.predictions,
    required this.onPredictionChanged,
  });

  @override
  State<MultiOptionPredictionSlidersWidget> createState() =>
      _MultiOptionPredictionSlidersWidgetState();
}

class _MultiOptionPredictionSlidersWidgetState
    extends State<MultiOptionPredictionSlidersWidget> {
  late Map<String, double> _predictions;

  @override
  void initState() {
    super.initState();
    _predictions = Map.from(widget.predictions);
    if (_predictions.isEmpty) {
      final equalShare = 100.0 / widget.options.length;
      for (final opt in widget.options) {
        _predictions[opt['id'] as String] = equalShare;
      }
    }
  }

  void _normalize() {
    final total = _predictions.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    setState(() {
      for (final key in _predictions.keys) {
        _predictions[key] = (_predictions[key]! / total) * 100.0;
      }
    });
    widget.onPredictionChanged(Map.from(_predictions));
  }

  double get _total => _predictions.values.fold(0.0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNormalized = (_total - 100.0).abs() < 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Set win probabilities:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _normalize,
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('Normalize'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                textStyle: TextStyle(fontSize: 11.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
          decoration: BoxDecoration(
            color: isNormalized
                ? theme.colorScheme.tertiaryContainer
                : theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Icon(
                isNormalized ? Icons.check_circle : Icons.warning,
                size: 16,
                color: isNormalized
                    ? theme.colorScheme.onTertiaryContainer
                    : theme.colorScheme.onErrorContainer,
              ),
              SizedBox(width: 2.w),
              Text(
                'Total: ${_total.toStringAsFixed(1)}% ${isNormalized ? "✓" : "(tap Normalize)"}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isNormalized
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        ...widget.options.asMap().entries.map((entry) {
          final idx = entry.key;
          final option = entry.value;
          final optionId = option['id'] as String;
          final value = _predictions[optionId] ?? 0.0;
          final colors = [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary,
            Colors.orange,
            Colors.purple,
          ];
          final color = colors[idx % colors.length];
          return _buildSlider(context, option, optionId, value, color);
        }),
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context,
    Map<String, dynamic> option,
    String optionId,
    double value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  option['title'] as String? ?? 'Option',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: 5,
            ),
            child: Slider(
              value: value.clamp(0.0, 100.0),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) {
                setState(() => _predictions[optionId] = v);
                widget.onPredictionChanged(Map.from(_predictions));
              },
            ),
          ),
        ],
      ),
    );
  }
}
