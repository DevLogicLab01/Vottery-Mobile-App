import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class EncryptionStatusWidget extends StatelessWidget {
  final Map<String, dynamic> encryptionStatus;

  const EncryptionStatusWidget({super.key, required this.encryptionStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final encryptionEnabled = encryptionStatus['encryption_enabled'] ?? false;
    final blockchainSync = encryptionStatus['blockchain_sync'] ?? false;
    final successRate = encryptionStatus['verification_success_rate'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            encryptionEnabled ? AppTheme.accentLight : AppTheme.errorLight,
            encryptionEnabled ? AppTheme.primaryLight : AppTheme.warningLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'Encryption',
              encryptionEnabled ? 'Active' : 'Inactive',
              encryptionEnabled ? Icons.lock : Icons.lock_open,
              theme,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildStatusCard(
              'Blockchain',
              blockchainSync ? 'Synced' : 'Not Synced',
              blockchainSync ? Icons.cloud_done : Icons.cloud_off,
              theme,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildStatusCard(
              'Success Rate',
              '${successRate.toStringAsFixed(1)}%',
              Icons.verified,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 6.w),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 10.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
