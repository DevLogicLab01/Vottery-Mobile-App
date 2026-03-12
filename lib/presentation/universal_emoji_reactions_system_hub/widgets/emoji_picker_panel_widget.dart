import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class EmojiPickerPanelWidget extends StatefulWidget {
  final Function(Emoji) onEmojiSelected;

  const EmojiPickerPanelWidget({super.key, required this.onEmojiSelected});

  @override
  State<EmojiPickerPanelWidget> createState() => _EmojiPickerPanelWidgetState();
}

class _EmojiPickerPanelWidgetState extends State<EmojiPickerPanelWidget> {
  final List<String> _recentlyUsed = ['👍', '❤️', '😂', '😮', '🎉'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: theme.dialogBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          _buildRecentlyUsed(theme),
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                widget.onEmojiSelected(emoji);
              },
              config: Config(
                height: 50.h,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 28.sp,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  gridPadding: EdgeInsets.zero,
                  backgroundColor: theme.dialogBackgroundColor,
                  buttonMode: ButtonMode.MATERIAL,
                ),
                skinToneConfig: const SkinToneConfig(),
                categoryViewConfig: CategoryViewConfig(
                  indicatorColor: AppTheme.primaryLight,
                  iconColor: theme.colorScheme.onSurfaceVariant,
                  iconColorSelected: AppTheme.primaryLight,
                  backgroundColor: theme.dialogBackgroundColor,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: theme.dialogBackgroundColor,
                  buttonColor: theme.colorScheme.surfaceContainerHighest,
                  buttonIconColor: theme.colorScheme.onSurfaceVariant,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: theme.dialogBackgroundColor,
                  buttonIconColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Choose Emoji Reaction',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            '3000+ emojis available',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyUsed(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recently Used',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: _recentlyUsed.map((emoji) {
              return GestureDetector(
                onTap: () {
                  widget.onEmojiSelected(Emoji(emoji, emoji));
                },
                child: Container(
                  margin: EdgeInsets.only(right: 3.w),
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(emoji, style: TextStyle(fontSize: 28.sp)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
