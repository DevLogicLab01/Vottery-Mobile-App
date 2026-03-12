import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/creator_churn_prediction_service.dart';

class AtRiskCreatorCardWidget extends StatelessWidget {
  final ChurnPrediction prediction;
  final VoidCallback? onSendSms;
  final VoidCallback? onSendEmail;
  final VoidCallback? onViewProfile;

  const AtRiskCreatorCardWidget({
    super.key,
    required this.prediction,
    this.onSendSms,
    this.onSendEmail,
    this.onViewProfile,
  });

  Color get _riskColor {
    switch (prediction.riskLevel) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  String get _tierLabel {
    switch (prediction.tier.toLowerCase()) {
      case 'platinum':
        return '💎 Platinum';
      case 'gold':
        return '🥇 Gold';
      case 'silver':
        return '🥈 Silver';
      default:
        return '🥉 Bronze';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _riskColor.withAlpha(77), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 1.5.h),
            _buildChurnGauge(),
            SizedBox(height: 1.5.h),
            _buildDriversList(),
            SizedBox(height: 1.5.h),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _riskColor.withAlpha(38),
          backgroundImage: prediction.avatarUrl != null
              ? NetworkImage(prediction.avatarUrl!)
              : null,
          child: prediction.avatarUrl == null
              ? Text(
                  prediction.creatorName.isNotEmpty
                      ? prediction.creatorName[0].toUpperCase()
                      : 'C',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: _riskColor,
                  ),
                )
              : null,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prediction.creatorName,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.3.h),
              Text(
                _tierLabel,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
              decoration: BoxDecoration(
                color: _riskColor.withAlpha(31),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                prediction.riskLevel.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: _riskColor,
                ),
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'In ${prediction.churnTimeframeDays}d',
              style: TextStyle(
                fontSize: 10.sp,
                color: _riskColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChurnGauge() {
    final probability = prediction.churnProbability;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Churn Probability',
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF6B7280)),
            ),
            Text(
              '${(probability * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: _riskColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: probability,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildDriversList() {
    if (prediction.primaryDrivers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Drivers',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: 0.5.h),
        ...prediction.primaryDrivers.take(2).map((driver) {
          final impact = driver['impact_percentage'] as int? ?? 0;
          return Padding(
            padding: EdgeInsets.only(bottom: 0.3.h),
            child: Row(
              children: [
                Icon(Icons.arrow_downward, size: 12, color: _riskColor),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    driver['driver'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$impact%',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: _riskColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (!prediction.interventionSent) ...[
          Expanded(
            child: _ActionButton(
              icon: Icons.sms_outlined,
              label: 'SMS',
              color: const Color(0xFF3B82F6),
              onTap: onSendSms,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _ActionButton(
              icon: Icons.email_outlined,
              label: 'Email',
              color: const Color(0xFF8B5CF6),
              onTap: onSendEmail,
            ),
          ),
          SizedBox(width: 2.w),
        ],
        if (prediction.interventionSent)
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 0.8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Intervention Sent',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!prediction.interventionSent) SizedBox(width: 0),
        Expanded(
          child: _ActionButton(
            icon: Icons.person_outline,
            label: 'Profile',
            color: const Color(0xFF6B7280),
            onTap: onViewProfile,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 0.8.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
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
    );
  }
}
