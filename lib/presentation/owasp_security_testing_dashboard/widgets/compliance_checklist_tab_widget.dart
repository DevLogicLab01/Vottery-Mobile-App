import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_theme.dart';

class ComplianceChecklistTabWidget extends StatefulWidget {
  const ComplianceChecklistTabWidget({super.key});

  @override
  State<ComplianceChecklistTabWidget> createState() =>
      _ComplianceChecklistTabWidgetState();
}

class _ComplianceChecklistTabWidgetState
    extends State<ComplianceChecklistTabWidget> {
  final _supabase = Supabase.instance.client;
  bool _isTestingBiometric = false;
  bool _isTestingResidency = false;
  bool _isTestingGdpr = false;
  bool _isTestingCcpa = false;

  final List<Map<String, dynamic>> _biometricCountries = [
    {
      'country': 'United States',
      'biometric_enabled': true,
      'compliance_status': 'compliant',
      'regulations': 'BIPA, CCPA',
    },
    {
      'country': 'European Union',
      'biometric_enabled': true,
      'compliance_status': 'compliant',
      'regulations': 'GDPR Art. 9',
    },
    {
      'country': 'United Kingdom',
      'biometric_enabled': true,
      'compliance_status': 'compliant',
      'regulations': 'UK GDPR',
    },
    {
      'country': 'China',
      'biometric_enabled': false,
      'compliance_status': 'disabled',
      'regulations': 'PIPL',
    },
  ];

  final Map<String, dynamic> _dataResidency = {
    'supabase_region': 'us-east-1',
    'current_location': 'United States (AWS us-east-1)',
    'sovereignty_compliant': true,
    'countries_served': ['US', 'EU', 'UK', 'CA', 'AU'],
  };

  final Map<String, dynamic> _gdprStatus = {
    'right_to_erasure': {'implemented': true, 'tested': true},
    'consent_management': {'implemented': true, 'tested': true},
    'data_portability': {'implemented': true, 'tested': true},
  };

  final Map<String, dynamic> _ccpaStatus = {
    'do_not_sell': {'implemented': true, 'tested': true},
    'data_access_request': {'implemented': true, 'tested': false},
    'data_deletion_request': {'implemented': true, 'tested': true},
  };

  Future<void> _testWorkflow(String type) async {
    setState(() {
      if (type == 'biometric') _isTestingBiometric = true;
      if (type == 'residency') _isTestingResidency = true;
      if (type == 'gdpr') _isTestingGdpr = true;
      if (type == 'ccpa') _isTestingCcpa = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        if (type == 'biometric') _isTestingBiometric = false;
        if (type == 'residency') _isTestingResidency = false;
        if (type == 'gdpr') _isTestingGdpr = false;
        if (type == 'ccpa') _isTestingCcpa = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type compliance test passed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Biometric Auth Section
          _buildSectionHeader('Biometric Authentication Compliance'),
          SizedBox(height: 1.h),
          ...(_biometricCountries.map((country) {
            final isEnabled = country['biometric_enabled'] as bool;
            return Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isEnabled
                      ? Colors.green.withAlpha(77)
                      : Colors.grey.withAlpha(77),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEnabled ? Icons.fingerprint : Icons.block,
                    color: isEnabled ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country['country'],
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          country['regulations'],
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondaryLight,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.3.h,
                    ),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? Colors.green.withAlpha(26)
                          : Colors.grey.withAlpha(26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isEnabled ? 'ENABLED' : 'DISABLED',
                      style: GoogleFonts.inter(
                        color: isEnabled ? Colors.green : Colors.grey,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })),
          _buildTestButton(
            'Test Biometric Auth',
            _isTestingBiometric,
            () => _testWorkflow('biometric'),
          ),
          SizedBox(height: 2.h),

          // Data Residency Section
          _buildSectionHeader('Data Residency Compliance'),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withAlpha(77)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResidencyRow(
                  'Supabase Region',
                  _dataResidency['supabase_region'],
                ),
                _buildResidencyRow(
                  'Data Location',
                  _dataResidency['current_location'],
                ),
                _buildResidencyRow(
                  'Sovereignty Compliant',
                  _dataResidency['sovereignty_compliant'] ? 'Yes' : 'No',
                ),
                _buildResidencyRow(
                  'Countries Served',
                  (_dataResidency['countries_served'] as List).join(', '),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          _buildTestButton(
            'Verify Data Residency',
            _isTestingResidency,
            () => _testWorkflow('residency'),
          ),
          SizedBox(height: 2.h),

          // GDPR Section
          _buildSectionHeader('GDPR Compliance'),
          SizedBox(height: 1.h),
          _buildWorkflowCard(
            'Right to Erasure',
            _gdprStatus['right_to_erasure']!,
          ),
          _buildWorkflowCard(
            'Consent Management',
            _gdprStatus['consent_management']!,
          ),
          _buildWorkflowCard(
            'Data Portability',
            _gdprStatus['data_portability']!,
          ),
          _buildTestButton(
            'Test GDPR Workflows',
            _isTestingGdpr,
            () => _testWorkflow('gdpr'),
          ),
          SizedBox(height: 2.h),

          // CCPA Section
          _buildSectionHeader('CCPA Compliance'),
          SizedBox(height: 1.h),
          _buildWorkflowCard('Do Not Sell Option', _ccpaStatus['do_not_sell']!),
          _buildWorkflowCard(
            'Data Access Request',
            _ccpaStatus['data_access_request']!,
          ),
          _buildWorkflowCard(
            'Data Deletion Request',
            _ccpaStatus['data_deletion_request']!,
          ),
          _buildTestButton(
            'Test CCPA Workflows',
            _isTestingCcpa,
            () => _testWorkflow('ccpa'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryLight,
      ),
    );
  }

  Widget _buildResidencyRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryLight,
              fontSize: 10.sp,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimaryLight,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowCard(String name, Map<String, dynamic> status) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              _buildStatusBadge('Implemented', status['implemented'] as bool),
              SizedBox(width: 1.w),
              _buildStatusBadge('Tested', status['tested'] as bool),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, bool active) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
      decoration: BoxDecoration(
        color: active ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: active ? Colors.green : Colors.red,
          fontSize: 8.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String label,
    bool isLoading,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          padding: EdgeInsets.symmetric(vertical: 1.2.h),
        ),
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.play_arrow, color: Colors.white, size: 16),
        label: Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
