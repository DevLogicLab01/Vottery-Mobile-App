import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/stripe_connect_service.dart';
import '../../../theme/app_theme.dart';

class AutomatedPayoutSchedulingWidget extends StatefulWidget {
  final Map<String, dynamic> currentSchedule;
  final VoidCallback onScheduleUpdated;

  const AutomatedPayoutSchedulingWidget({
    super.key,
    required this.currentSchedule,
    required this.onScheduleUpdated,
  });

  @override
  State<AutomatedPayoutSchedulingWidget> createState() =>
      _AutomatedPayoutSchedulingWidgetState();
}

class _AutomatedPayoutSchedulingWidgetState
    extends State<AutomatedPayoutSchedulingWidget> {
  final StripeConnectService _stripeService = StripeConnectService.instance;

  String _selectedFrequency = 'monthly';
  double _minimumThreshold = 10.0;
  bool _autoPayoutEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSchedule();
  }

  void _loadCurrentSchedule() {
    if (widget.currentSchedule.isNotEmpty) {
      setState(() {
        _selectedFrequency =
            widget.currentSchedule['schedule_type'] ?? 'monthly';
        _minimumThreshold =
            ((widget.currentSchedule['minimum_payout_amount'] ?? 10.0) as num)
                .toDouble();
        _autoPayoutEnabled =
            widget.currentSchedule['auto_payout_enabled'] ?? true;
      });
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);

    try {
      final success = await _stripeService.updatePayoutSchedule(
        frequency: _selectedFrequency,
        minimumThreshold: _minimumThreshold,
        autoPayoutEnabled: _autoPayoutEnabled,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout schedule updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onScheduleUpdated();
      }
    } catch (e) {
      debugPrint('Save schedule error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update schedule'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Payout Frequency'),
          SizedBox(height: 2.h),
          _buildFrequencySelector(),
          SizedBox(height: 3.h),
          _buildSectionTitle('Minimum Payout Threshold'),
          SizedBox(height: 2.h),
          _buildThresholdSlider(),
          SizedBox(height: 3.h),
          _buildSectionTitle('Automatic Processing'),
          SizedBox(height: 2.h),
          _buildAutoPayoutToggle(),
          SizedBox(height: 3.h),
          _buildSchedulePreview(),
          SizedBox(height: 3.h),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryLight,
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          _buildFrequencyOption(
            'weekly',
            'Weekly',
            'Every Monday',
            Icons.calendar_today,
          ),
          Divider(height: 2.h),
          _buildFrequencyOption(
            'biweekly',
            'Bi-weekly',
            '1st and 15th of each month',
            Icons.calendar_view_week,
          ),
          Divider(height: 2.h),
          _buildFrequencyOption(
            'monthly',
            'Monthly',
            '1st of each month',
            Icons.calendar_month,
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedFrequency == value;

    return InkWell(
      onTap: () => setState(() => _selectedFrequency = value),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryLight
                  : AppTheme.textSecondaryLight,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryLight, size: 6.w),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdSlider() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Minimum Amount',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              Text(
                '\$${_minimumThreshold.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          Slider(
            value: _minimumThreshold,
            min: 10.0,
            max: 500.0,
            divisions: 49,
            activeColor: AppTheme.primaryLight,
            onChanged: (value) {
              setState(() => _minimumThreshold = value);
            },
          ),
          Text(
            'Payouts will only process when balance exceeds this amount',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoPayoutToggle() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Automatic Payouts',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Automatically process payouts based on your schedule',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoPayoutEnabled,
            activeThumbColor: AppTheme.primaryLight,
            onChanged: (value) {
              setState(() => _autoPayoutEnabled = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePreview() {
    String nextPayoutDate = _calculateNextPayoutDate();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.accentLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.accentLight, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Schedule Preview',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Next payout: $nextPayoutDate',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            'Minimum: \$${_minimumThreshold.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            'Auto-processing: ${_autoPayoutEnabled ? "Enabled" : "Disabled"}',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSchedule,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: _isSaving
            ? SizedBox(
                width: 5.w,
                height: 5.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Save Schedule',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  String _calculateNextPayoutDate() {
    final now = DateTime.now();
    DateTime nextDate;

    switch (_selectedFrequency) {
      case 'weekly':
        final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
        nextDate = now.add(
          Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday),
        );
        break;
      case 'biweekly':
        if (now.day < 15) {
          nextDate = DateTime(now.year, now.month, 15);
        } else {
          nextDate = DateTime(now.year, now.month + 1, 1);
        }
        break;
      case 'monthly':
      default:
        nextDate = DateTime(now.year, now.month + 1, 1);
        break;
    }

    return '${nextDate.month}/${nextDate.day}/${nextDate.year}';
  }
}
