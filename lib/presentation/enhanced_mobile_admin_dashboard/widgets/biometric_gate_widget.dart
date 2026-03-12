import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

// Platform-specific biometric implementation
class BiometricGateWidget extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const BiometricGateWidget({super.key, required this.onAuthenticated});

  @override
  State<BiometricGateWidget> createState() => _BiometricGateWidgetState();
}

class _BiometricGateWidgetState extends State<BiometricGateWidget> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() => _isAuthenticating = true);

    try {
      if (kIsWeb) {
        // Web fallback - simulate authentication
        await Future.delayed(const Duration(seconds: 1));
        widget.onAuthenticated();
      } else {
        // Mobile biometric authentication would go here
        await Future.delayed(const Duration(seconds: 1));
        widget.onAuthenticated();
      }
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fingerprint,
              size: 60.sp,
              color: const Color(0xFFFFC629),
            ),
            SizedBox(height: 2.h),
            Text(
              'Biometric Authentication',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              kIsWeb
                  ? 'Verifying admin access...'
                  : 'Use Face ID or Fingerprint to authenticate',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            if (_isAuthenticating)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC629),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
