import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Audio Visualization Widget
/// Real-time waveform display and processing indicators
class AudioVisualizationWidget extends StatelessWidget {
  final bool isActive;
  final double audioLevel;

  const AudioVisualizationWidget({
    super.key,
    required this.isActive,
    required this.audioLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        height: 15.h,
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.graphic_eq,
                  color: isActive ? Colors.green : Colors.grey,
                  size: 20.sp,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Audio Visualization',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(20, (index) {
                  final barHeight = isActive
                      ? (audioLevel * (1 + sin(index * 0.5))) * 100
                      : 10.0;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 3.w,
                    height: barHeight.clamp(10.0, 100.0),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withAlpha(179)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
