import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BrandDiscoveryFeedWidget extends StatelessWidget {
  final List<Map<String, dynamic>> opportunities;
  final VoidCallback onRefresh;

  const BrandDiscoveryFeedWidget({
    super.key,
    required this.opportunities,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (opportunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No opportunities available',
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
        itemCount: opportunities.length,
        itemBuilder: (context, index) {
          final opportunity = opportunities[index];
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
                  opportunity['campaign_name'] ?? 'Untitled Campaign',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Budget: \$${opportunity['budget'] ?? 0}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
