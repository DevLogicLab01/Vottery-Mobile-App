import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/otp_verification_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

class OTPEmailVerificationHub extends StatefulWidget {
  const OTPEmailVerificationHub({super.key});

  @override
  State<OTPEmailVerificationHub> createState() =>
      _OTPEmailVerificationHubState();
}

class _OTPEmailVerificationHubState extends State<OTPEmailVerificationHub> {
  final _otpService = OTPVerificationService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  final List<Map<String, dynamic>> _recentVerifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load analytics for demo election
    final analytics = await _otpService.getOTPAnalytics('demo-election-id');

    setState(() {
      _analytics = analytics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'OTPEmailVerificationHub',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'OTP Email Verification Hub',
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryLight),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVerificationStatusHeader(),
                      SizedBox(height: 3.h),
                      _buildOTPConfigurationSection(),
                      SizedBox(height: 3.h),
                      _buildVerificationAnalytics(),
                      SizedBox(height: 3.h),
                      _buildSecurityMonitoring(),
                      SizedBox(height: 3.h),
                      _buildOTPInputDemo(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildVerificationStatusHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Status',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Email OTP Security',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                ],
              ),
              CustomIconWidget(
                iconName: 'verified_user',
                size: 12.w,
                color: Colors.white,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatusMetric(
                  'Enabled Elections',
                  '12',
                  Icons.how_to_vote,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatusMetric(
                  'Success Rate',
                  '${_analytics['successRate'] ?? '0.0'}%',
                  Icons.check_circle,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatusMetric(
                  'Security Score',
                  '98/100',
                  Icons.security,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 6.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.white.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPConfigurationSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'settings',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 2.w),
              Text(
                'OTP Configuration',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildConfigItem('Code Length', '6 digits', Icons.pin),
          _buildConfigItem('Expiration Time', '10 minutes', Icons.timer),
          _buildConfigItem('Max Attempts', '3 attempts', Icons.repeat),
          _buildConfigItem('Resend Cooldown', '1 minute', Icons.schedule),
          _buildConfigItem(
            'Cryptographic Generation',
            'Random.secure()',
            Icons.lock,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 5.w, color: AppTheme.primaryLight),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationAnalytics() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'analytics',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 2.w),
              Text(
                'Verification Analytics',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticCard(
                  'Total Verifications',
                  '${_analytics['total'] ?? 0}',
                  Colors.blue,
                  Icons.email,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildAnalyticCard(
                  'Verified',
                  '${_analytics['verified'] ?? 0}',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticCard(
                  'Failed',
                  '${_analytics['failed'] ?? 0}',
                  Colors.red,
                  Icons.error,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildAnalyticCard(
                  'Expired',
                  '${_analytics['expired'] ?? 0}',
                  Colors.orange,
                  Icons.timer_off,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Avg. Verification Time',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  '${_analytics['avgVerificationTimeSeconds'] ?? 0}s',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityMonitoring() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'security',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 2.w),
              Text(
                'Security Monitoring',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSecurityItem(
            'IP Tracking',
            'All verification attempts logged with IP address',
            Icons.location_on,
            Colors.blue,
          ),
          _buildSecurityItem(
            'Device Fingerprinting',
            'Unique device identification for fraud detection',
            Icons.fingerprint,
            Colors.purple,
          ),
          _buildSecurityItem(
            'Attempt Monitoring',
            'Real-time tracking of failed verification patterns',
            Icons.visibility,
            Colors.orange,
          ),
          _buildSecurityItem(
            'Audit Logging',
            'Comprehensive audit trail for all OTP operations',
            Icons.history,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 5.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPInputDemo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'dialpad',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 2.w),
              Text(
                'OTP Input UI Demo',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Enter 6-digit verification code',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              6,
              (index) => Container(
                width: 12.w,
                height: 6.h,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryLight, width: 2),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Text(
                    '',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Resend Code (60s)',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
              Text(
                '3 attempts remaining',
                style: TextStyle(fontSize: 11.sp, color: Colors.orange),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 5.w),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    '✅ Email Verified - Badge displayed on ballot UI',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
