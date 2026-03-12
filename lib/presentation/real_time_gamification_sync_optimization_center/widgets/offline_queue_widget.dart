import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class OfflineQueueWidget extends StatelessWidget {
  final List<Map<String, dynamic>> queue;
  final VoidCallback onSync;

  const OfflineQueueWidget({
    super.key,
    required this.queue,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Offline VP Transaction Queue',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: onSync,
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Sync'),
              ),
            ],
          ),
        ),
        Expanded(
          child: queue.isEmpty
              ? Center(
                  child: Text(
                    'No queued transactions',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final transaction = queue[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: ListTile(
                        leading: Icon(
                          Icons.pending_actions,
                          color: Colors.orange,
                        ),
                        title: Text(
                          transaction['description'] ?? 'VP Transaction',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        subtitle: Text(
                          'Retry: ${transaction['retry_count'] ?? 0}/3',
                          style: TextStyle(fontSize: 10.sp),
                        ),
                        trailing: Text(
                          '+${transaction['vp_amount']} VP',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
