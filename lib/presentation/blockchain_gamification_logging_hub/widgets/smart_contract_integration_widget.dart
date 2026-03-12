import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SmartContractIntegrationWidget extends StatelessWidget {
  const SmartContractIntegrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, color: Colors.indigo.shade700, size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Smart Contract Integration',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildInfoRow('Network', 'Polygon (Matic)', Icons.public),
          SizedBox(height: 1.h),
          _buildInfoRow('Gas Optimization', 'Batch Processing', Icons.speed),
          SizedBox(height: 1.h),
          _buildInfoRow('Verification', 'Automated', Icons.verified),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Smart contract deployment coming soon'),
                ),
              );
            },
            icon: Icon(Icons.rocket_launch, size: 16.sp),
            label: Text('Deploy Contract', style: TextStyle(fontSize: 11.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: Colors.indigo.shade600),
        SizedBox(width: 2.w),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        ),
      ],
    );
  }
}
