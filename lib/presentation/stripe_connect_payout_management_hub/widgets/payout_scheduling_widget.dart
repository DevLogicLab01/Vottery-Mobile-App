import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/payout_management_service.dart';
import '../../../theme/app_theme.dart';

class PayoutSchedulingWidget extends StatefulWidget {
  const PayoutSchedulingWidget({super.key});

  @override
  State<PayoutSchedulingWidget> createState() => _PayoutSchedulingWidgetState();
}

class _PayoutSchedulingWidgetState extends State<PayoutSchedulingWidget> {
  final PayoutManagementService _payoutService =
      PayoutManagementService.instance;

  bool _isLoading = true;
  String _scheduleType = 'weekly';
  double _minimumThreshold = 25.0;
  DateTime? _nextPayoutDate;
  double _estimatedNextPayout = 0.0;

  @override
  void initState() {
    super.initState();
    _loadScheduleConfig();
  }

  Future<void> _loadScheduleConfig() async {
    setState(() => _isLoading = true);

    try {
      final config = await _payoutService.getPayoutSchedule();

      setState(() {
        _scheduleType = config['schedule_type'] ?? 'weekly';
        _minimumThreshold = config['minimum_threshold'] ?? 25.0;
        _nextPayoutDate = config['next_payout_date'] != null
            ? DateTime.parse(config['next_payout_date'])
            : null;
        _estimatedNextPayout =
            150.0; // Mock value - would come from earnings service
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveScheduleConfig() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Schedule Change'),
        content: Text(
          'Update payout schedule to $_scheduleType with \$${_minimumThreshold.toStringAsFixed(0)} minimum threshold?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await _payoutService.updatePayoutSchedule(
                scheduleType: _scheduleType,
                minimumThreshold: _minimumThreshold,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payout schedule updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadScheduleConfig();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update schedule'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _getCountdownText() {
    if (_nextPayoutDate == null) return 'Not scheduled';

    final now = DateTime.now();
    final difference = _nextPayoutDate!.difference(now);

    if (difference.isNegative) return 'Processing...';

    final days = difference.inDays;
    final hours = difference.inHours % 24;

    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''} ${hours}h';
    } else {
      return '${hours}h ${difference.inMinutes % 60}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Schedule Type Selector
          Text(
            'Payout Schedule',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildScheduleOption(
                        'Weekly',
                        'Every Monday',
                        Icons.calendar_today,
                        'weekly',
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _buildScheduleOption(
                        'Monthly',
                        '1st of month',
                        Icons.calendar_month,
                        'monthly',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Next Payout Countdown
          Text(
            'Next Payout',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryLight, AppTheme.vibrantYellow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                Icon(Icons.schedule, size: 15.w, color: Colors.white),
                SizedBox(height: 1.h),
                Text(
                  _getCountdownText(),
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _nextPayoutDate != null
                      ? 'Until ${_nextPayoutDate!.toString().substring(0, 10)}'
                      : 'No payout scheduled',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Minimum Threshold Slider
          Text(
            'Minimum Payout Threshold',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${_minimumThreshold.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    Text(
                      'Range: \$25 - \$500',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Slider(
                  value: _minimumThreshold,
                  min: 25.0,
                  max: 500.0,
                  divisions: 95,
                  activeColor: AppTheme.primaryLight,
                  inactiveColor: AppTheme.primaryLight.withValues(alpha: 0.3),
                  onChanged: (value) {
                    setState(() => _minimumThreshold = value);
                  },
                ),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.vibrantYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.vibrantYellow,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Estimated next payout: \$${_estimatedNextPayout.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveScheduleConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                'Save Schedule Configuration',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleOption(
    String title,
    String subtitle,
    IconData icon,
    String value,
  ) {
    final isSelected = _scheduleType == value;

    return GestureDetector(
      onTap: () => setState(() => _scheduleType = value),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : Colors.grey[300]!,
            width: 2.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryLight : Colors.grey[600],
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryLight
                    : AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
