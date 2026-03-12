import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class TelnyxSmsProviderManagementDashboard extends StatefulWidget {
  const TelnyxSmsProviderManagementDashboard({super.key});

  @override
  State<TelnyxSmsProviderManagementDashboard> createState() =>
      _TelnyxSmsProviderManagementDashboardState();
}

class _TelnyxSmsProviderManagementDashboardState
    extends State<TelnyxSmsProviderManagementDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telnyx SMS Provider Management'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80.sp, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'Telnyx SMS Provider Management',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'This screen provides comprehensive SMS infrastructure oversight\nwith intelligent failover monitoring.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go to SMS Provider Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}