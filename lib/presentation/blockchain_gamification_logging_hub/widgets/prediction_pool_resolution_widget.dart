import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PredictionPoolResolutionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> predictions;
  final VoidCallback onRefresh;

  const PredictionPoolResolutionWidget({
    super.key,
    required this.predictions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, size: 48.sp, color: Colors.grey.shade400),
              SizedBox(height: 2.h),
              Text(
                'No prediction resolutions logged yet',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: predictions.length,
        itemBuilder: (context, index) {
          final prediction = predictions[index];
          final network = prediction['blockchain_network'] ?? 'polygon';
          final isVerified = prediction['verification_status'] == 'verified';
          final timestamp = DateTime.parse(prediction['created_at']);

          return Card(
            margin: EdgeInsets.only(bottom: 2.h),
            elevation: 2,
            child: ListTile(
              leading: Icon(
                Icons.trending_up,
                color: Colors.purple.shade700,
                size: 24.sp,
              ),
              title: Text(
                'Prediction Resolved',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network: ${network.toUpperCase()}',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  Text(
                    'Time: ${timestamp.toString().substring(0, 19)}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                isVerified ? Icons.verified : Icons.pending,
                color: isVerified ? Colors.green : Colors.orange,
              ),
            ),
          );
        },
      ),
    );
  }
}
