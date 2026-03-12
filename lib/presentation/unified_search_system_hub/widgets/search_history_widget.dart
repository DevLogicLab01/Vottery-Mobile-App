import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SearchHistoryWidget extends StatelessWidget {
  final List<String> history;
  final Function(String) onHistoryTap;
  final VoidCallback onClearAll;

  const SearchHistoryWidget({
    super.key,
    required this.history,
    required this.onHistoryTap,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16.sp, color: Colors.grey),
            SizedBox(width: 2.w),
            Text(
              'Recent Searches',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClearAll,
              child: Text(
                'Clear All',
                style: TextStyle(fontSize: 12.sp, color: Colors.red),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length > 10 ? 10 : history.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(Icons.history, size: 16.sp, color: Colors.grey),
              title: Text(history[index], style: TextStyle(fontSize: 13.sp)),
              trailing: Icon(Icons.north_west, size: 12.sp, color: Colors.grey),
              onTap: () => onHistoryTap(history[index]),
            );
          },
        ),
      ],
    );
  }
}
