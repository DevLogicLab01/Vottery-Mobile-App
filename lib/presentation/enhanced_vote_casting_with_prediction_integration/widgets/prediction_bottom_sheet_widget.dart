import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './binary_prediction_slider_widget.dart';
import './multi_option_prediction_sliders_widget.dart';
import './confirm_prediction_card_widget.dart';
import './animated_success_overlay_widget.dart';

/// Prediction bottom sheet that adapts to election type
class PredictionBottomSheetWidget extends StatefulWidget {
  final String electionId;
  final String electionType; // 'plurality', 'ranked_choice', 'approval', 'plus_minus'
  final List<Map<String, dynamic>> options;
  final Function(Map<String, double>) onSubmitPrediction;

  const PredictionBottomSheetWidget({
    super.key,
    required this.electionId,
    required this.electionType,
    required this.options,
    required this.onSubmitPrediction,
  });

  @override
  State<PredictionBottomSheetWidget> createState() =>
      _PredictionBottomSheetWidgetState();
}

class _PredictionBottomSheetWidgetState
    extends State<PredictionBottomSheetWidget> {
  Map<String, double> _predictions = {};
  bool _showConfirmCard = false;
  bool _isLoading = false;
  bool _showSuccess = false;

  // Mock crowd predictions
  Map<String, double> get _crowdPredictions {
    final result = <String, double>{};
    final count = widget.options.length;
    for (int i = 0; i < count; i++) {
      final optId = widget.options[i]['id'] as String;
      result[optId] = count == 2
          ? (i == 0 ? 65.0 : 35.0)
          : 100.0 / count;
    }
    return result;
  }

  int get _potentialVpReward {
    // Calculate based on how different user prediction is from crowd
    double diff = 0;
    for (final opt in widget.options) {
      final optId = opt['id'] as String;
      final userPct = _predictions[optId] ?? 0.0;
      final crowdPct = _crowdPredictions[optId] ?? 0.0;
      diff += (userPct - crowdPct).abs();
    }
    return (100 + (diff * 0.5)).round();
  }

  Future<void> _submitPrediction() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    widget.onSubmitPrediction(_predictions);
    setState(() {
      _isLoading = false;
      _showSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 1.5.h),
                  width: 10.w,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Predict Outcome',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Earn VP based on accuracy',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prediction slider UI based on election type
                      if (!_showConfirmCard) ..._buildPredictionUI(context),

                      if (!_showConfirmCard) ...[
                        SizedBox(height: 3.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _predictions.isEmpty
                                ? null
                                : () => setState(() => _showConfirmCard = true),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            ),
                            child: Text(
                              'Review Prediction',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ),
                      ],

                      if (_showConfirmCard) ...[
                        ConfirmPredictionCardWidget(
                          options: widget.options,
                          userPredictions: _predictions,
                          crowdPredictions: _crowdPredictions,
                          potentialVpReward: _potentialVpReward,
                          isLoading: _isLoading,
                          onConfirm: _submitPrediction,
                        ),
                        SizedBox(height: 1.h),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showConfirmCard = false),
                          child: const Text('← Edit Prediction'),
                        ),
                      ],

                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Success overlay
        if (_showSuccess)
          Positioned.fill(
            child: AnimatedSuccessOverlayWidget(
              onDismiss: () {
                Navigator.pop(context, _predictions);
              },
            ),
          ),
      ],
    );
  }

  List<Widget> _buildPredictionUI(BuildContext context) {
    switch (widget.electionType) {
      case 'plurality':
        return [
          BinaryPredictionSliderWidget(
            options: widget.options,
            predictions: _predictions,
            onPredictionChanged: (p) => setState(() => _predictions = p),
          ),
        ];
      case 'ranked_choice':
        return [
          MultiOptionPredictionSlidersWidget(
            options: widget.options,
            predictions: _predictions,
            onPredictionChanged: (p) => setState(() => _predictions = p),
          ),
        ];
      case 'approval':
        return [
          _buildApprovalPredictionUI(context),
        ];
      default:
        return [
          BinaryPredictionSliderWidget(
            options: widget.options,
            predictions: _predictions,
            onPredictionChanged: (p) => setState(() => _predictions = p),
          ),
        ];
    }
  }

  Widget _buildApprovalPredictionUI(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set approval probability per option (0-100% independent):',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        ...widget.options.asMap().entries.map((entry) {
          final idx = entry.key;
          final option = entry.value;
          final optionId = option['id'] as String;
          final value = _predictions[optionId] ?? 50.0;
          final colors = [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary,
            Colors.orange,
          ];
          final color = colors[idx % colors.length];
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.5.h,
                      ),
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
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: color,
                    inactiveTrackColor: color.withValues(alpha: 0.2),
                    thumbColor: color,
                    trackHeight: 5,
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (v) {
                      setState(() {
                        _predictions[optionId] = v;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}