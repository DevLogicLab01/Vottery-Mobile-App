import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ActiveCampaignsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> campaigns;
  final VoidCallback onRefresh;

  const ActiveCampaignsWidget({
    super.key,
    required this.campaigns,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No active campaigns',
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
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
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
                  campaign['campaign_name'] ?? 'Untitled Campaign',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Status: Active',
                  style: TextStyle(fontSize: 11.sp, color: Colors.green),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
