import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Widget for vote totals visibility toggle with one-way enforcement
class VoteVisibilityToggleWidget extends StatelessWidget {
  final String voteVisibility;
  final Function(String) onChanged;
  final bool isElectionActive;

  const VoteVisibilityToggleWidget({
    super.key,
    required this.voteVisibility,
    required this.onChanged,
    this.isElectionActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = voteVisibility == 'visible';
    final canToggle = voteVisibility == 'hidden';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: AppTheme.primaryLight,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Vote Totals Visibility',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              Switch(
                value: isVisible,
                onChanged: canToggle
                    ? (value) {
                        if (value) {
                          _showConfirmationDialog(context);
                        }
                      }
                    : null,
                activeThumbColor: AppTheme.accentLight,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            isVisible
                ? 'Real-time vote totals are visible to all voters during voting'
                : 'Vote totals are hidden during voting to prevent bandwagon effect',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
          if (!canToggle && isVisible) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.orange.shade700, size: 5.w),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Visibility cannot be changed back to hidden once enabled',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Important Information',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                _buildInfoPoint(
                  'Default state is hidden to prevent bandwagon effect',
                ),
                _buildInfoPoint(
                  'You can change from hidden to visible during voting',
                ),
                _buildInfoPoint(
                  'Once visible, it cannot be changed back to hidden',
                ),
                _buildInfoPoint(
                  'Final results are always revealed at election end',
                ),
                _buildInfoPoint(
                  'As creator, you can always see vote totals in analytics',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: 10.sp, color: Colors.blue.shade600),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10.sp, color: Colors.blue.shade600),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 6.w),
            SizedBox(width: 2.w),
            Expanded(child: Text('Confirm Visibility Change')),
          ],
        ),
        content: Text(
          'Are you sure you want to make vote totals visible? This action cannot be reversed. Once visible, voters will see real-time vote counts.',
          style: TextStyle(fontSize: 12.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onChanged('visible');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLight,
              foregroundColor: Colors.white,
            ),
            child: Text('Make Visible'),
          ),
        ],
      ),
    );
  }
}
