import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Voice Command Library Widget
/// Displays available voice commands with pronunciation guides
class VoiceCommandLibraryWidget extends StatelessWidget {
  const VoiceCommandLibraryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final commands = [
      {
        'command': 'Analyze security',
        'description': 'Run AI security analysis',
        'icon': Icons.security,
      },
      {
        'command': 'Show my quests',
        'description': 'Display available quests',
        'icon': Icons.emoji_events,
      },
      {
        'command': 'Check VP balance',
        'description': 'View Vottery Points',
        'icon': Icons.account_balance_wallet,
      },
      {
        'command': 'Recent votes',
        'description': 'Show voting history',
        'icon': Icons.history,
      },
      {
        'command': 'AI recommendations',
        'description': 'Get personalized suggestions',
        'icon': Icons.lightbulb,
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.library_books, color: Colors.orange, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Voice Command Library',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ...commands.map(
              (cmd) => _buildCommandTile(
                cmd['command'] as String,
                cmd['description'] as String,
                cmd['icon'] as IconData,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandTile(String command, String description, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: Colors.blue, size: 18.sp),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"$command"',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
