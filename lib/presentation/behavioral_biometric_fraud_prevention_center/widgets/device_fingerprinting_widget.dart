import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DeviceFingerprintingWidget extends StatefulWidget {
  final List<Map<String, dynamic>> sessions;

  const DeviceFingerprintingWidget({super.key, required this.sessions});

  @override
  State<DeviceFingerprintingWidget> createState() =>
      _DeviceFingerprintingWidgetState();
}

class _DeviceFingerprintingWidgetState
    extends State<DeviceFingerprintingWidget> {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  Map<String, dynamic> _currentDeviceInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        setState(() {
          _currentDeviceInfo = {
            'device_id': 'web-browser',
            'model': 'Web Browser',
            'os_version': 'Web',
            'manufacturer': 'Browser',
            'brand': 'Web',
          };
        });
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        setState(() {
          _currentDeviceInfo = {
            'device_id': androidInfo.id,
            'model': androidInfo.model,
            'os_version': 'Android ${androidInfo.version.release}',
            'manufacturer': androidInfo.manufacturer,
            'brand': androidInfo.brand,
          };
        });
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        setState(() {
          _currentDeviceInfo = {
            'device_id': iosInfo.identifierForVendor ?? 'unknown',
            'model': iosInfo.model,
            'os_version': 'iOS ${iosInfo.systemVersion}',
            'manufacturer': 'Apple',
            'brand': 'Apple',
          };
        });
      }
    } catch (e) {
      debugPrint('Load device info error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Fingerprinting',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildCurrentDeviceCard(),
          SizedBox(height: 2.h),
          Text(
            'Active Device Sessions',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          ...widget.sessions.map((session) => _buildDeviceSessionCard(session)),
        ],
      ),
    );
  }

  Widget _buildCurrentDeviceCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.phone_android,
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 2.w),
              Text(
                'Current Device Profile',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildDeviceInfoRow('Device ID', _currentDeviceInfo['device_id']),
          _buildDeviceInfoRow('Model', _currentDeviceInfo['model']),
          _buildDeviceInfoRow('OS Version', _currentDeviceInfo['os_version']),
          _buildDeviceInfoRow(
            'Manufacturer',
            _currentDeviceInfo['manufacturer'],
          ),
          _buildDeviceInfoRow('Brand', _currentDeviceInfo['brand']),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, size: 5.w, color: Colors.green),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Device verified and trusted',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
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

  Widget _buildDeviceSessionCard(Map<String, dynamic> session) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fingerprint: ${session['device_fingerprint']}',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Icon(Icons.fingerprint, size: 6.w, color: AppTheme.primaryLight),
            ],
          ),
          SizedBox(height: 1.h),
          _buildDeviceInfoRow('User ID', session['user_id']),
          _buildDeviceInfoRow('Session ID', session['session_id']),
          _buildDeviceInfoRow(
            'Risk Level',
            session['risk_level'].toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            value ?? 'N/A',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
