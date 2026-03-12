import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TrendingSuggestionsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final Function(String) onSuggestionTap;

  const TrendingSuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, size: 16.sp, color: Colors.orange),
            SizedBox(width: 2.w),
            Text(
              'Trending Searches',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withAlpha(51),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              title: Text(
                suggestion['query'] ?? '',
                style: TextStyle(fontSize: 13.sp),
              ),
              subtitle: Text(
                '${suggestion['search_count'] ?? 0} searches',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 12.sp),
              onTap: () => onSuggestionTap(suggestion['query'] ?? ''),
            );
          },
        ),
      ],
    );
  }
}
