import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AtRiskCreatorCardWidget extends StatelessWidget {
  final Map<String, dynamic> creator;
  final VoidCallback? onSendSMS;
  final VoidCallback? onSendEmail;
  final VoidCallback? onViewProfile;
  const AtRiskCreatorCardWidget({
    super.key,
    required this.creator,
    this.onSendSMS,
    this.onSendEmail,
    this.onViewProfile,
  });

  Color _riskColor(double p) => p > 0.7
      ? const Color(0xFFEF4444)
      : p > 0.5
      ? const Color(0xFFF97316)
      : const Color(0xFFF59E0B);
  String _riskLabel(double p) => p > 0.7
      ? 'Critical'
      : p > 0.5
      ? 'High'
      : 'Medium';

  @override
  Widget build(BuildContext context) {
    final probability =
        (creator['churn_probability'] as num?)?.toDouble() ?? 0.0;
    final drivers =
        (creator['primary_drivers'] as List?)?.cast<String>() ?? <String>[];
    final daysToChurn = creator['churn_timeframe_days'] as int? ?? 14;
    final riskColor = _riskColor(probability);
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: riskColor.withAlpha(77), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: riskColor.withAlpha(51),
                child: Text(
                  (creator['creator_name'] as String? ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator['creator_name'] as String? ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      creator['tier'] as String? ?? 'Bronze',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  _riskLabel(probability),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: riskColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Churn Risk',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: probability,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: riskColor,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      '${(probability * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Predicted churn in',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '$daysToChurn days',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (drivers.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Wrap(
              spacing: 1.w,
              runSpacing: 0.5.h,
              children: drivers
                  .map(
                    (d) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          SizedBox(height: 1.h),
          Row(
            children: [
              _ActionBtn(
                icon: Icons.sms,
                label: 'SMS',
                color: const Color(0xFF3B82F6),
                onTap: onSendSMS,
              ),
              SizedBox(width: 1.w),
              _ActionBtn(
                icon: Icons.email,
                label: 'Email',
                color: const Color(0xFF10B981),
                onTap: onSendEmail,
              ),
              SizedBox(width: 1.w),
              _ActionBtn(
                icon: Icons.person,
                label: 'Profile',
                color: const Color(0xFF8B5CF6),
                onTap: onViewProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 0.8.h),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: color.withAlpha(77)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              SizedBox(width: 1.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
