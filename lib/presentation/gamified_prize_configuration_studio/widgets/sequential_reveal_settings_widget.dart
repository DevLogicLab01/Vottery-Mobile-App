import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class SequentialRevealSettingsWidget extends StatefulWidget {
  final bool enabled;
  final int delaySeconds;
  final String animationStyle;
  final Function(bool, int, String) onChanged;

  const SequentialRevealSettingsWidget({
    super.key,
    required this.enabled,
    required this.delaySeconds,
    required this.animationStyle,
    required this.onChanged,
  });

  @override
  State<SequentialRevealSettingsWidget> createState() =>
      _SequentialRevealSettingsWidgetState();
}

class _SequentialRevealSettingsWidgetState
    extends State<SequentialRevealSettingsWidget> {
  late bool _enabled;
  late int _delaySeconds;
  late String _animationStyle;

  final List<Map<String, dynamic>> _animationStyles = [
    {
      'value': 'dramatic',
      'label': 'Dramatic',
      'description': 'Slow build-up with suspense',
      'icon': Icons.theater_comedy,
    },
    {
      'value': 'fast',
      'label': 'Fast',
      'description': 'Quick succession reveals',
      'icon': Icons.fast_forward,
    },
    {
      'value': 'smooth',
      'label': 'Smooth',
      'description': 'Balanced pacing',
      'icon': Icons.animation,
    },
  ];

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _delaySeconds = widget.delaySeconds;
    _animationStyle = widget.animationStyle;
  }

  void _notifyChange() {
    widget.onChanged(_enabled, _delaySeconds, _animationStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sequential Reveal',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _enabled,
                onChanged: (value) {
                  setState(() => _enabled = value);
                  _notifyChange();
                },
                activeThumbColor: AppTheme.primaryColor,
              ),
            ],
          ),
          if (_enabled) ...[
            SizedBox(height: 1.h),
            Text(
              'Winners will be revealed one by one with animation',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Text(
              'Delay Between Reveals: ${_delaySeconds}s',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _delaySeconds.toDouble(),
              min: 2,
              max: 10,
              divisions: 8,
              label: '${_delaySeconds}s',
              onChanged: (value) {
                setState(() => _delaySeconds = value.toInt());
                _notifyChange();
              },
              activeColor: AppTheme.primaryColor,
            ),
            SizedBox(height: 2.h),
            Text(
              'Animation Style',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            ..._animationStyles.map((style) {
              final isSelected = _animationStyle == style['value'];
              return GestureDetector(
                onTap: () {
                  setState(() => _animationStyle = style['value']);
                  _notifyChange();
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 1.h),
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withAlpha(26)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        style['icon'],
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey[600],
                        size: 18.sp,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              style['label'],
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              style['description'],
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                          size: 18.sp,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
