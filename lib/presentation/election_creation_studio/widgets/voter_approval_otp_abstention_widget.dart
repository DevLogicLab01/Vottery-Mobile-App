import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Toggles for: Require Voter Approval, OTP before voting, Track Abstentions.
/// Matches Web ParticipationSettingsForm (voterApprovalRequired, otpRequired, abstentionTrackingEnabled).
class VoterApprovalOtpAbstentionWidget extends StatelessWidget {
  final bool requireVoterApproval;
  final bool otpRequired;
  final bool abstentionTrackingEnabled;
  final ValueChanged<bool> onRequireVoterApprovalChanged;
  final ValueChanged<bool> onOtpRequiredChanged;
  final ValueChanged<bool> onAbstentionTrackingChanged;

  const VoterApprovalOtpAbstentionWidget({
    super.key,
    required this.requireVoterApproval,
    required this.otpRequired,
    required this.abstentionTrackingEnabled,
    required this.onRequireVoterApprovalChanged,
    required this.onOtpRequiredChanged,
    required this.onAbstentionTrackingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Voting Controls',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildRow(
            title: 'Require Voter Approval',
            subtitle: 'Manually approve each voter before they can participate',
            value: requireVoterApproval,
            onChanged: onRequireVoterApprovalChanged,
          ),
          SizedBox(height: 1.5.h),
          _buildRow(
            title: 'Require OTP Verification',
            subtitle: 'Send one-time password via email before voting',
            value: otpRequired,
            onChanged: onOtpRequiredChanged,
          ),
          SizedBox(height: 1.5.h),
          _buildRow(
            title: 'Track Abstentions',
            subtitle: 'Record intentional non-votes in results',
            value: abstentionTrackingEnabled,
            onChanged: onAbstentionTrackingChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
