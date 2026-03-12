import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class SyncStatusOverviewWidget extends StatelessWidget {
  final int activeOperations;
  final int queueLength;
  final String networkHealth;
  final bool isOnline;
  final bool isSyncing;
  final VoidCallback onManualSync;

  const SyncStatusOverviewWidget({
    super.key,
    required this.activeOperations,
    required this.queueLength,
    required this.networkHealth,
    required this.isOnline,
    required this.isSyncing,
    required this.onManualSync,
  });

  Color _getHealthColor() {
    switch (networkHealth) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'poor':
        return Colors.orange;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.primaryLight.withAlpha(204)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusCard(
                icon: Icons.sync,
                label: 'Active Operations',
                value: activeOperations.toString(),
                color: Colors.white,
              ),
              _buildStatusCard(
                icon: Icons.queue,
                label: 'Queue Length',
                value: queueLength.toString(),
                color: Colors.white,
              ),
              _buildStatusCard(
                icon: Icons.network_check,
                label: 'Network Health',
                value: networkHealth.toUpperCase(),
                color: _getHealthColor(),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.green.withAlpha(51)
                        : Colors.red.withAlpha(51),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: isOnline ? Colors.green : Colors.red,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isOnline ? Icons.cloud_done : Icons.cloud_off,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              ElevatedButton.icon(
                onPressed: isSyncing ? null : onManualSync,
                icon: Icon(
                  isSyncing ? Icons.hourglass_empty : Icons.sync,
                  size: 18.sp,
                ),
                label: Text(
                  isSyncing ? 'Syncing...' : 'Manual Sync',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryLight,
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white70),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
