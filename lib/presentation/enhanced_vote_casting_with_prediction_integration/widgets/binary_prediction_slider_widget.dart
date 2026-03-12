import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Binary prediction slider for plurality voting - two options summing to 100%
class BinaryPredictionSliderWidget extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final Map<String, double> predictions;
  final Function(Map<String, double>) onPredictionChanged;

  const BinaryPredictionSliderWidget({
    super.key,
    required this.options,
    required this.predictions,
    required this.onPredictionChanged,
  });

  @override
  State<BinaryPredictionSliderWidget> createState() =>
      _BinaryPredictionSliderWidgetState();
}

class _BinaryPredictionSliderWidgetState
    extends State<BinaryPredictionSliderWidget> {
  late Map<String, double> _predictions;

  @override
  void initState() {
    super.initState();
    _predictions = Map.from(widget.predictions);
    if (_predictions.isEmpty && widget.options.length >= 2) {
      _predictions[widget.options[0]['id']] = 50.0;
      _predictions[widget.options[1]['id']] = 50.0;
    }
  }

  void _onSliderChanged(String optionId, double value) {
    setState(() {
      _predictions[optionId] = value;
      // Auto-adjust the other option to sum to 100%
      if (widget.options.length == 2) {
        final otherId =
            widget.options.firstWhere((o) => o['id'] != optionId)['id']
                as String;
        _predictions[otherId] = 100.0 - value;
      }
    });
    widget.onPredictionChanged(Map.from(_predictions));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = widget.options.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your prediction (must sum to 100%)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        ...options.map((option) {
          final optionId = option['id'] as String;
          final value = _predictions[optionId] ?? 50.0;
          return _buildSlider(context, option, optionId, value);
        }),
        SizedBox(height: 1.h),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              'Total: ${_predictions.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context,
    Map<String, dynamic> option,
    String optionId,
    double value,
  ) {
    final theme = Theme.of(context);
    final colors = [theme.colorScheme.primary, theme.colorScheme.secondary];
    final idx = widget.options.indexWhere((o) => o['id'] == optionId);
    final color = idx < colors.length ? colors[idx] : theme.colorScheme.primary;

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
                  '${value.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              thumbShape: _DiamondSliderThumb(
                thumbRadius: 12,
                color: color,
                value: value,
              ),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) => _onSliderChanged(optionId, v),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiamondSliderThumb extends SliderComponentShape {
  final double thumbRadius;
  final Color color;
  final double value;

  const _DiamondSliderThumb({
    required this.thumbRadius,
    required this.color,
    required this.value,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - thumbRadius);
    path.lineTo(center.dx + thumbRadius, center.dy);
    path.lineTo(center.dx, center.dy + thumbRadius);
    path.lineTo(center.dx - thumbRadius, center.dy);
    path.close();
    canvas.drawPath(path, paint);

    // Draw percentage label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${this.value.toStringAsFixed(0)}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
}
