import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PartnershipProposalsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> proposals;
  final VoidCallback onRefresh;

  const PartnershipProposalsWidget({
    super.key,
    required this.proposals,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (proposals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No proposals submitted',
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
        itemCount: proposals.length,
        itemBuilder: (context, index) {
          final proposal = proposals[index];
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
                  proposal['brand_partnerships']?['campaign_name'] ??
                      'Unknown Campaign',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Status: ${proposal['status'] ?? "pending"}',
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
