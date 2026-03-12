import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AllowCommentsToggleWidget extends StatelessWidget {
  final bool allowComments;
  final ValueChanged<bool> onChanged;

  const AllowCommentsToggleWidget({
    super.key,
    required this.allowComments,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: SwitchListTile(
        title: Text(
          'Allow Comments',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Let users comment on this election. Disable to restrict commenting.',
          style: TextStyle(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        secondary: Icon(
          Icons.comment,
          color: allowComments
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        value: allowComments,
        onChanged: onChanged,
        activeThumbColor: theme.colorScheme.primary,
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      ),
    );
  }
}
