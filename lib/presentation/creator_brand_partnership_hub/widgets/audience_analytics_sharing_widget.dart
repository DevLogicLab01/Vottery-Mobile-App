import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AudienceAnalyticsSharingWidget extends StatelessWidget {
  final String creatorId;

  const AudienceAnalyticsSharingWidget({super.key, required this.creatorId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(3.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Theme.of(context).primaryColor,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Audience Analytics',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Share anonymized audience insights with potential brand partners',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () {
              _generateShareableReport(context);
            },
            icon: const Icon(Icons.share, color: Colors.white),
            label: Text(
              'Generate Shareable Report',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              minimumSize: Size(double.infinity, 5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateShareableReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: const Text(
          'This will create a shareable PDF report with anonymized audience analytics including age distribution, gender split, location heatmap, and interest categories.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report generation started'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}
