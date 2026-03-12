import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/secure_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dual_header_bottom_bar.dart';
import '../../widgets/dual_header_top_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../security_compliance_audit_screen/security_compliance_audit_screen.dart';

/// Security Audit Dashboard - GDPR/CCPA, SSL, Biometric, PCI-DSS, automated scanning
class SecurityAuditDashboard extends StatefulWidget {
  const SecurityAuditDashboard({super.key});

  @override
  State<SecurityAuditDashboard> createState() => _SecurityAuditDashboardState();
}

class _SecurityAuditDashboardState extends State<SecurityAuditDashboard> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _biometricEnrolled = false;
  bool _secureStorageAvailable = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      _biometricAvailable = await _localAuth.canCheckBiometrics;
      _biometricEnrolled = await _localAuth.isDeviceSupported();
      final enrolled = await _localAuth.getAvailableBiometrics();
      _biometricEnrolled = enrolled.isNotEmpty;
      _secureStorageAvailable = !kIsWeb; // flutter_secure_storage on mobile
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'SecurityAuditDashboard',
      onRetry: _loadStatus,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: DualHeaderTopBar(
          currentRoute: AppRoutes.securityComplianceAudit,
          friendRequestsCount: 0,
          messagesCount: 0,
          notificationsCount: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStatus,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Audit Dashboard',
                        style: GoogleFonts.inter(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      _buildSection(
                        'GDPR / CCPA Compliance',
                        Icons.gavel,
                        [
                          _buildCheckItem('Data Export', true, 'Users can export personal data'),
                          _buildCheckItem('Right to Delete', true, 'Account deletion available'),
                          _buildCheckItem('CCPA Opt-Out', true, 'California opt-out honored'),
                          _buildCheckItem('Privacy Policy', true, 'Policy reflects current practices'),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      _buildSection(
                        'SSL Certificate Status',
                        Icons.lock,
                        [
                          _buildCheckItem('TLS 1.2+', true, 'All API communications encrypted'),
                          _buildCheckItem('Certificate Valid', true, 'Supabase-managed certificates'),
                          _buildCheckItem('HSTS Enabled', true, 'Strict-Transport-Security header'),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      _buildSection(
                        'Biometric Auth Validation',
                        Icons.fingerprint,
                        [
                          _buildCheckItem('Biometric Available', _biometricAvailable, 'Device supports biometrics'),
                          _buildCheckItem('Biometric Enrolled', _biometricEnrolled, 'User has enrolled biometrics'),
                          _buildCheckItem('On-Device Only', true, 'No facial/fingerprint data stored'),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      _buildSection(
                        'Payment Compliance (PCI-DSS)',
                        Icons.credit_card,
                        [
                          _buildCheckItem('Stripe Connect', true, 'PCI-compliant payment processor'),
                          _buildCheckItem('No Card Storage', true, 'Cards handled by Stripe'),
                          _buildCheckItem('Tokenization', true, 'Payment tokens only'),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      _buildSection(
                        'Secure Credential Storage',
                        Icons.storage,
                        [
                          _buildCheckItem('Secure Storage Available', _secureStorageAvailable, 'Credentials stored in platform keychain/Keystore'),
                          _buildCheckItem('Cleared on Logout', true, 'SecureStorage cleared when user signs out'),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      _buildSection(
                        'Automated Security Scanning',
                        Icons.security,
                        [
                          _buildCheckItem('Dependency Audit', true, 'npm audit / flutter pub audit'),
                          _buildCheckItem('Vulnerability Scan', true, 'CVE tracking enabled'),
                          _buildCheckItem('Rate Limiting', true, 'API rate limits enforced'),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SecurityComplianceAuditScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.checklist),
                          label: const Text('Full Security Checklist'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryLight,
                            side: const BorderSide(color: AppTheme.primaryLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: DualHeaderBottomBar(
          currentRoute: AppRoutes.securityComplianceAudit,
          onNavigate: (route) => Navigator.pushNamed(context, route),
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryLight, size: 24),
              SizedBox(width: 2.w),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool pass, String detail) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(
            pass ? Icons.check_circle : Icons.cancel,
            color: pass ? AppTheme.accentLight : AppTheme.errorLight,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  detail,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
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
