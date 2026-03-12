import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AdLoadingStatesWidget extends StatelessWidget {
  final bool isAdSdkInitialized;

  const AdLoadingStatesWidget({super.key, required this.isAdSdkInitialized});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ad Loading States & Error Handling',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Manage ad loading states, error handling, and fallback mechanisms',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          _buildLoadingStateCard(
            'Loading State',
            'Show shimmer while ad loads',
            Icons.hourglass_empty,
            Colors.blue,
            'Prevents blank spaces during ad load',
          ),
          SizedBox(height: 2.h),
          _buildLoadingStateCard(
            'Error State',
            'Graceful fallback when ad fails',
            Icons.error_outline,
            Colors.red,
            'Shows alternative content on failure',
          ),
          SizedBox(height: 2.h),
          _buildLoadingStateCard(
            'Success State',
            'Display ad when loaded',
            Icons.check_circle,
            Colors.green,
            'Seamless ad display after load',
          ),
          SizedBox(height: 3.h),
          _buildErrorHandlingSection(),
          SizedBox(height: 2.h),
          _buildFallbackMechanisms(),
        ],
      ),
    );
  }

  Widget _buildLoadingStateCard(
    String title,
    String description,
    IconData icon,
    Color color,
    String details,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    details,
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorHandlingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, size: 20.sp, color: Colors.orange),
                SizedBox(width: 2.w),
                Text(
                  'Error Handling',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildErrorTypeRow(
              'Network Error',
              'Retry with exponential backoff',
            ),
            Divider(height: 2.h),
            _buildErrorTypeRow('Ad Not Available', 'Show fallback content'),
            Divider(height: 2.h),
            _buildErrorTypeRow('SDK Not Initialized', 'Reinitialize SDK'),
            Divider(height: 2.h),
            _buildErrorTypeRow('Invalid Ad Unit', 'Log error and skip'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorTypeRow(String errorType, String action) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            errorType,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
          ),
        ),
        Icon(Icons.arrow_forward, size: 16.sp, color: Colors.grey),
        SizedBox(width: 2.w),
        Expanded(
          flex: 2,
          child: Text(
            action,
            style: TextStyle(fontSize: 11.sp, color: Colors.blue),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackMechanisms() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup, size: 20.sp, color: Colors.purple),
                SizedBox(width: 2.w),
                Text(
                  'Fallback Mechanisms',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Ensure optimal user experience when ads fail to load',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),
            _buildFallbackOption(
              'Alternative Content',
              'Show platform content instead of ads',
              Icons.article,
            ),
            SizedBox(height: 1.h),
            _buildFallbackOption(
              'Retry Logic',
              'Attempt to reload ad with delay',
              Icons.refresh,
            ),
            SizedBox(height: 1.h),
            _buildFallbackOption(
              'Skip Ad Slot',
              'Continue without ad if critical',
              Icons.skip_next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackOption(String title, String description, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: Colors.grey[700]),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
