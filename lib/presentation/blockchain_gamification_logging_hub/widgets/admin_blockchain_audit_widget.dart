import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AdminBlockchainAuditWidget extends StatelessWidget {
  const AdminBlockchainAuditWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.red.shade700,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Admin Audit Tools',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildAuditButton(
            context,
            icon: Icons.search,
            label: 'Transaction Search',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Transaction search tool coming soon')),
              );
            },
          ),
          SizedBox(height: 1.h),
          _buildAuditButton(
            context,
            icon: Icons.verified_user,
            label: 'Hash Chain Verification',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hash chain verification tool coming soon'),
                ),
              );
            },
          ),
          SizedBox(height: 1.h),
          _buildAuditButton(
            context,
            icon: Icons.account_tree,
            label: 'Merkle Tree Generator',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Merkle tree generator coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.red.shade700, size: 16.sp),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
