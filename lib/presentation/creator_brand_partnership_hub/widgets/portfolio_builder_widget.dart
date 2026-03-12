import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PortfolioBuilderWidget extends StatelessWidget {
  final List<Map<String, dynamic>> portfolioItems;
  final VoidCallback onRefresh;

  const PortfolioBuilderWidget({
    super.key,
    required this.portfolioItems,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (portfolioItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No portfolio items yet',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: EdgeInsets.all(3.w),
        itemCount: portfolioItems.length,
        itemBuilder: (context, index) {
          final item = portfolioItems[index];
          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Untitled',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Votes: ${item['total_votes'] ?? 0} | Engagement: ${item['engagement_rate'] ?? 0}%',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
