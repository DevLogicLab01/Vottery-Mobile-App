import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EmojiReactionPickerWidget extends StatelessWidget {
  final String messageId;
  final Function(String emoji) onEmojiSelected;

  const EmojiReactionPickerWidget({
    super.key,
    required this.messageId,
    required this.onEmojiSelected,
  });

  static const List<Map<String, String>> _reactions = [
    {'emoji': '👍', 'name': 'thumbs_up'},
    {'emoji': '❤️', 'name': 'heart'},
    {'emoji': '😂', 'name': 'laugh'},
    {'emoji': '😮', 'name': 'wow'},
    {'emoji': '😢', 'name': 'sad'},
    {'emoji': '😡', 'name': 'angry'},
    {'emoji': '🔥', 'name': 'fire'},
    {'emoji': '👏', 'name': 'clap'},
    {'emoji': '🤔', 'name': 'thinking'},
    {'emoji': '👎', 'name': 'thumbs_down'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.dialogBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(1.w),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'React to Message',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
              ),
              itemCount: _reactions.length,
              itemBuilder: (context, index) {
                final reaction = _reactions[index];
                return InkWell(
                  onTap: () => onEmojiSelected(reaction['name']!),
                  borderRadius: BorderRadius.circular(3.w),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3.w),
                    ),
                    child: Center(
                      child: Text(
                        reaction['emoji']!,
                        style: TextStyle(fontSize: 30.sp),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
