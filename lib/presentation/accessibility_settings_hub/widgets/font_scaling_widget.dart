import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/accessibility_preferences_service.dart';

class FontScalingWidget extends StatefulWidget {
  final double currentScale;
  final ValueChanged<double> onScaleChanged;

  const FontScalingWidget({
    super.key,
    required this.currentScale,
    required this.onScaleChanged,
  });

  @override
  State<FontScalingWidget> createState() => _FontScalingWidgetState();
}

class _FontScalingWidgetState extends State<FontScalingWidget> {
  late double _tempScale;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _tempScale = widget.currentScale;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presets = AccessibilityPreferencesService.instance.presetScales;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Font Size Scaling',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),

            // Slider with percentage labels
            Row(
              children: [
                Text('80%', style: TextStyle(fontSize: 10.sp)),
                Expanded(
                  child: Slider(
                    value: _tempScale,
                    min: 0.8,
                    max: 1.2,
                    divisions: 4,
                    label: '${(_tempScale * 100).toInt()}%',
                    onChanged: (value) {
                      setState(() => _tempScale = value);
                      AccessibilityPreferencesService.instance
                          .trackFontPreviewViewed(value);
                    },
                    onChangeEnd: (value) => _updateFontScale(value),
                  ),
                ),
                Text('120%', style: TextStyle(fontSize: 10.sp)),
              ],
            ),
            SizedBox(height: 1.h),

            // Current scale display
            Center(
              child: Text(
                'Current: ${(_tempScale * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Preset buttons
            Row(
              children: presets.entries.map((entry) {
                final isSelected = (_tempScale - entry.value).abs() < 0.01;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: OutlinedButton(
                      onPressed: () => _updateFontScale(entry.value),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? theme.colorScheme.primary.withAlpha(51)
                            : null,
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 2.h),

            // Live preview
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'This is how text will appear at ${(_tempScale * 100).toInt()}% scale.',
                    style: TextStyle(fontSize: (12 * _tempScale).sp),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'The quick brown fox jumps over the lazy dog.',
                    style: TextStyle(
                      fontSize: (14 * _tempScale).sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),

            // Reset button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUpdating ? null : () => _updateFontScale(1.0),
                icon: Icon(Icons.refresh, size: 14.sp),
                label: Text(
                  'Reset to Default',
                  style: TextStyle(fontSize: 11.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateFontScale(double scale) async {
    setState(() {
      _tempScale = scale;
      _isUpdating = true;
    });

    final success = await AccessibilityPreferencesService.instance
        .updateFontScale(scale);

    if (mounted) {
      setState(() => _isUpdating = false);

      if (success) {
        widget.onScaleChanged(scale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Font size updated to ${(scale * 100).toInt()}%'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update font size'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
