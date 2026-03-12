import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BlockchainStatusHeaderWidget extends StatelessWidget {
  final String networkHealth;
  final int gasFeeGwei;
  final int transactionQueue;
  final int lastBlock;
  final String syncStatus;

  const BlockchainStatusHeaderWidget({
    super.key,
    required this.networkHealth,
    required this.gasFeeGwei,
    required this.transactionQueue,
    required this.lastBlock,
    required this.syncStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isHealthy = networkHealth == 'Healthy';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHealthy
              ? [Colors.green.shade700, Colors.teal.shade700]
              : [Colors.red.shade700, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Health',
                    style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                  ),
                  Row(
                    children: [
                      Icon(
                        isHealthy ? Icons.check_circle : Icons.warning,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        networkHealth,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Gas Fee',
                    style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                  ),
                  Text(
                    '$gasFeeGwei Gwei',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem('Queue', '$transactionQueue', Icons.queue),
              _buildStatusItem(
                'Block',
                '#${lastBlock.toString().substring(0, 8)}...',
                Icons.grid_on,
              ),
              _buildStatusItem('Status', syncStatus, Icons.sync),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16.sp),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 10.sp),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
