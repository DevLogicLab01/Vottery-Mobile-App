import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class GlobalToggleSwitchesWidget extends StatelessWidget {
  final bool electionEnabled;
  final bool socialEnabled;
  final bool adEnabled;
  final Function(String contentType, bool enabled) onToggleChanged;

  const GlobalToggleSwitchesWidget({
    super.key,
    required this.electionEnabled,
    required this.socialEnabled,
    required this.adEnabled,
    required this.onToggleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Global Toggle Switches',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Enable or disable content types globally',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 2.h),
            _buildToggleItem(
              context,
              'Election Content',
              'Elections, voting, and political content',
              electionEnabled,
              Icons.how_to_vote,
              Colors.purple,
              (value) => _handleToggle(context, 'election', value),
            ),
            Divider(height: 3.h),
            _buildToggleItem(
              context,
              'Social Content',
              'Posts, stories, and social interactions',
              socialEnabled,
              Icons.people,
              Colors.blue,
              (value) => _handleToggle(context, 'social', value),
            ),
            Divider(height: 3.h),
            _buildToggleItem(
              context,
              'Ad Content',
              'Sponsored content and advertisements',
              adEnabled,
              Icons.ads_click,
              Colors.green,
              (value) => _handleToggle(context, 'ad', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    BuildContext context,
    String title,
    String description,
    bool enabled,
    IconData icon,
    Color color,
    Function(bool) onChanged,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(value: enabled, onChanged: onChanged, activeThumbColor: color),
      ],
    );
  }

  Future<void> _handleToggle(
    BuildContext context,
    String contentType,
    bool newValue,
  ) async {
    if (!newValue) {
      // Show confirmation dialog when disabling
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 2.w),
              Text('Disable Content Type'),
            ],
          ),
          content: Text(
            'Disabling ${contentType.toUpperCase()} content will:\n\n'
            '• Hide all $contentType content from users\n'
            '• Impact user engagement metrics\n'
            '• Affect content distribution balance\n\n'
            'Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Disable'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        onToggleChanged(contentType, newValue);
      }
    } else {
      onToggleChanged(contentType, newValue);
    }
  }
}
