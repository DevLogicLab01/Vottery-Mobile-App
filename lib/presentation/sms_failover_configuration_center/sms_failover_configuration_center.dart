import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';

class SmsFailoverConfigurationCenter extends StatefulWidget {
  const SmsFailoverConfigurationCenter({super.key});

  @override
  State<SmsFailoverConfigurationCenter> createState() =>
      _SmsFailoverConfigurationCenterState();
}

class _SmsFailoverConfigurationCenterState
    extends State<SmsFailoverConfigurationCenter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Failover Configuration'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_suggest, size: 80.sp, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'SMS Failover Configuration Center',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'Manage intelligent provider switching with Claude AI-powered\nhealth analysis and automated restoration protocols.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.smsProviderDashboard);
              },
              child: const Text('Go to SMS Provider Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}