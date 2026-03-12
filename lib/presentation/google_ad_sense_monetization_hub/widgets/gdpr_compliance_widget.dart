import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/adsense_service.dart';

class GdprComplianceWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const GdprComplianceWidget({super.key, required this.onRefresh});

  @override
  State<GdprComplianceWidget> createState() => _GdprComplianceWidgetState();
}

class _GdprComplianceWidgetState extends State<GdprComplianceWidget> {
  final AdSenseService _adSenseService = AdSenseService.instance;
  bool _hasConsent = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
  }

  Future<void> _loadConsentStatus() async {
    setState(() => _isLoading = true);
    final consent = await _adSenseService.hasGdprConsent();
    setState(() {
      _hasConsent = consent;
      _isLoading = false;
    });
  }

  Future<void> _updateConsent(bool value) async {
    final success = await _adSenseService.updateGdprConsent(value);
    if (success) {
      setState(() => _hasConsent = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Personalized ads enabled' : 'Personalized ads disabled',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConsentCard(),
          SizedBox(height: 2.h),
          _buildPrivacyInfoCard(),
          SizedBox(height: 2.h),
          _buildAdBlockDetectionCard(),
        ],
      ),
    );
  }

  Widget _buildConsentCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: Colors.blue, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Ad Personalization',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Allow personalized ads based on your interests and activity',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),
            SwitchListTile(
              title: Text(
                'Personalized Ads',
                style: TextStyle(fontSize: 13.sp),
              ),
              subtitle: Text(
                _hasConsent ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: _hasConsent ? Colors.green : Colors.grey,
                ),
              ),
              value: _hasConsent,
              onChanged: _updateConsent,
              activeThumbColor: const Color(0xFFFFC629),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Privacy Information',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildInfoRow(
              'GDPR Compliant',
              'Full compliance with EU data protection',
            ),
            SizedBox(height: 1.h),
            _buildInfoRow(
              'CCPA Compliant',
              'California Consumer Privacy Act compliance',
            ),
            SizedBox(height: 1.h),
            _buildInfoRow('Data Control', 'You control your ad preferences'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdBlockDetectionCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, color: Colors.orange, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Ad Block Detection',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Support Vottery by allowing ads',
              style: TextStyle(fontSize: 13.sp),
            ),
            SizedBox(height: 1.h),
            Text(
              'Ads help us keep the platform free for everyone. Please consider whitelisting Vottery in your ad blocker.',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
