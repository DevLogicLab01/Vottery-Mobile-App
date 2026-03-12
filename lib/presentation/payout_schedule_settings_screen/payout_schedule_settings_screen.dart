import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/payout_automation_service.dart';
import '../../theme/app_theme.dart';

class PayoutScheduleSettingsScreen extends StatefulWidget {
  const PayoutScheduleSettingsScreen({super.key});

  @override
  State<PayoutScheduleSettingsScreen> createState() =>
      _PayoutScheduleSettingsScreenState();
}

class _PayoutScheduleSettingsScreenState
    extends State<PayoutScheduleSettingsScreen> {
  final PayoutAutomationService _payoutService =
      PayoutAutomationService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _tierConfigs = [];
  String _globalSchedule = 'weekly';
  bool _globalAutoEnabled = true;

  final Map<String, TextEditingController> _thresholdControllers = {};
  final Map<String, bool> _tierToggles = {};

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
  }

  @override
  void dispose() {
    for (var controller in _thresholdControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConfigurations() async {
    setState(() => _isLoading = true);

    try {
      final configs = await _payoutService.getAllPayoutScheduleConfigs();

      setState(() {
        _tierConfigs = configs;
        for (var config in configs) {
          final tierLevel = config['tier_level'] as String;
          _thresholdControllers[tierLevel] = TextEditingController(
            text: (config['minimum_threshold'] as num).toStringAsFixed(0),
          );
          _tierToggles[tierLevel] = config['auto_enabled'] as bool? ?? true;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      for (var config in _tierConfigs) {
        final tierLevel = config['tier_level'] as String;
        final threshold =
            double.tryParse(_thresholdControllers[tierLevel]?.text ?? '50') ??
            50.0;

        await _payoutService.updatePayoutScheduleConfig(
          tierLevel: tierLevel,
          scheduleFrequency: _globalSchedule,
          minimumThreshold: threshold,
          autoEnabled: _tierToggles[tierLevel] ?? true,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payout settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadConfigurations();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payout Schedule Settings',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryLight,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Global Settings
                  _buildSectionHeader('Global Settings'),
                  SizedBox(height: 2.h),
                  _buildGlobalSettingsCard(),
                  SizedBox(height: 3.h),

                  // Tier-Specific Configuration
                  _buildSectionHeader('Tier-Specific Configuration'),
                  SizedBox(height: 2.h),
                  ..._tierConfigs.map((config) => _buildTierCard(config)),

                  SizedBox(height: 3.h),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        'Save Settings',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimaryLight,
      ),
    );
  }

  Widget _buildGlobalSettingsCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Frequency (All Creators)',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            initialValue: _globalSchedule,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.5.h,
              ),
            ),
            items: [
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'biweekly', child: Text('Bi-weekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _globalSchedule = value);
              }
            },
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Master Auto-Payout Toggle',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Switch(
                value: _globalAutoEnabled,
                onChanged: (value) {
                  setState(() => _globalAutoEnabled = value);
                },
                activeThumbColor: AppTheme.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(Map<String, dynamic> config) {
    final tierLevel = config['tier_level'] as String;
    final tierName = _getTierDisplayName(tierLevel);
    final tierColor = _getTierColor(tierLevel);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: tierColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: tierColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: tierColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  tierName,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Spacer(),
              Switch(
                value: _tierToggles[tierLevel] ?? true,
                onChanged: (value) {
                  setState(() => _tierToggles[tierLevel] = value);
                },
                activeThumbColor: tierColor,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Minimum Threshold',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _thresholdControllers[tierLevel],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.5.h,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Schedule: ${_globalSchedule.toUpperCase()} • Auto: ${_tierToggles[tierLevel] == true ? "ON" : "OFF"}',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  String _getTierDisplayName(String tier) {
    final names = {
      'bronze': 'Bronze Tier',
      'silver': 'Silver Tier',
      'gold': 'Gold Tier',
      'platinum': 'Platinum Tier',
      'elite': 'Elite Tier',
    };
    return names[tier] ?? tier.toUpperCase();
  }

  Color _getTierColor(String tier) {
    final colors = {
      'bronze': Color(0xFFCD7F32),
      'silver': Color(0xFFC0C0C0),
      'gold': Color(0xFFFFD700),
      'platinum': Color(0xFFE5E4E2),
      'elite': Color(0xFF9B59B6),
    };
    return colors[tier] ?? AppTheme.primaryLight;
  }
}
