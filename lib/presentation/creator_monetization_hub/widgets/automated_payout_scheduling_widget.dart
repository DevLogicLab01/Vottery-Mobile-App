import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/payout_management_service.dart';
import '../../../theme/app_theme.dart';

class AutomatedPayoutSchedulingWidget extends StatefulWidget {
  const AutomatedPayoutSchedulingWidget({super.key});

  @override
  State<AutomatedPayoutSchedulingWidget> createState() =>
      _AutomatedPayoutSchedulingWidgetState();
}

class _AutomatedPayoutSchedulingWidgetState
    extends State<AutomatedPayoutSchedulingWidget> {
  final PayoutManagementService _payoutService =
      PayoutManagementService.instance;

  String _selectedFrequency = 'Weekly';
  final List<String> _frequencies = ['Weekly', 'Bi-weekly', 'Monthly'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automated Payout Scheduling',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedFrequency,
            decoration: InputDecoration(
              labelText: 'Payout Frequency',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            items: _frequencies.map((freq) {
              return DropdownMenuItem(value: freq, child: Text(freq));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedFrequency = value!);
            },
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              child: Text(
                'Save Schedule',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSchedule() async {
    final success = await _payoutService.updatePayoutSchedule(
      scheduleType: _selectedFrequency.toLowerCase(),
      minimumThreshold: 10.0,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout schedule updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
