import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Speaker notes widget displaying notes below slides
class SpeakerNotesWidget extends StatelessWidget {
  final String slideId;
  final VoidCallback onClose;

  const SpeakerNotesWidget({
    super.key,
    required this.slideId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 20.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Speaker Notes',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                iconSize: 18.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                'Start with a warm welcome and brief overview of the agenda. Emphasize the key benefits and address common concerns.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
