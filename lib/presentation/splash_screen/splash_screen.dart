import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/ip_geolocation_service.dart';

/// Splash Screen - Branded app launch with biometric initialization
///
/// Displays full-screen branded experience while performing critical background tasks:
/// - Checking authentication status
/// - Loading user preferences
/// - Initializing Supabase connection
/// - Preparing offline vote cache
/// - Determining navigation path based on user state
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    _checkLocationAndNavigate();
  }

  Future<void> _checkLocationAndNavigate() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 2));

    // Check IP geolocation
    final locationResult = await IPGeolocationService.validateUserLocation();

    if (!mounted) return;

    if (locationResult['allowed'] == false) {
      // Show blocked dialog
      _showAccessDeniedDialog(
        countryName: locationResult['country_name'] ?? 'Unknown',
        countryCode: locationResult['country_code'] ?? 'UNKNOWN',
        blockedReason:
            locationResult['blocked_reason'] ??
            'Service not available in your region',
      );
    } else {
      // Proceed to home
      Navigator.pushReplacementNamed(context, '/vote-dashboard');
    }
  }

  void _showAccessDeniedDialog({
    required String countryName,
    required String countryCode,
    required String blockedReason,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red[700], size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Access Restricted', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vottery is not available in your region.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getCountryFlag(countryCode),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        countryName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          countryCode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reason: $blockedReason',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We apologize for the inconvenience. This restriction is due to regulatory compliance requirements.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Exit', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  String _getCountryFlag(String countryCode) {
    if (countryCode == 'UNKNOWN') return '🌍';
    final codePoints = countryCode.toUpperCase().codeUnits;
    return String.fromCharCodes(codePoints.map((c) => 0x1F1E6 + (c - 0x41)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/img_app_logo.svg',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 24),
              const Text(
                'VOTTERY',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Verifying location...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}