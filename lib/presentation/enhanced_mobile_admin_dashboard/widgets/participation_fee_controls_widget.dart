import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/admin_management_service.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';

/// Widget for managing participation fee feature controls
class ParticipationFeeControlsWidget extends StatefulWidget {
  final Function()? onRefresh;

  const ParticipationFeeControlsWidget({super.key, this.onRefresh});

  @override
  State<ParticipationFeeControlsWidget> createState() =>
      _ParticipationFeeControlsWidgetState();
}

class _ParticipationFeeControlsWidgetState
    extends State<ParticipationFeeControlsWidget> {
  final AdminManagementService _adminService = AdminManagementService.instance;

  bool _isLoading = true;
  bool _isGloballyEnabled = false;
  List<String> _enabledCountries = [];
  List<String> _disabledCountries = [];
  bool _isSaving = false;

  final TextEditingController _countryController = TextEditingController();

  // Common country codes
  final List<Map<String, String>> _commonCountries = [
    {'code': 'US', 'name': 'United States'},
    {'code': 'CA', 'name': 'Canada'},
    {'code': 'GB', 'name': 'United Kingdom'},
    {'code': 'DE', 'name': 'Germany'},
    {'code': 'FR', 'name': 'France'},
    {'code': 'IT', 'name': 'Italy'},
    {'code': 'ES', 'name': 'Spain'},
    {'code': 'AU', 'name': 'Australia'},
    {'code': 'NZ', 'name': 'New Zealand'},
    {'code': 'JP', 'name': 'Japan'},
    {'code': 'CN', 'name': 'China'},
    {'code': 'IN', 'name': 'India'},
    {'code': 'BR', 'name': 'Brazil'},
    {'code': 'MX', 'name': 'Mexico'},
    {'code': 'ZA', 'name': 'South Africa'},
    {'code': 'NG', 'name': 'Nigeria'},
    {'code': 'KE', 'name': 'Kenya'},
    {'code': 'AE', 'name': 'United Arab Emirates'},
    {'code': 'SA', 'name': 'Saudi Arabia'},
    {'code': 'SG', 'name': 'Singapore'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFeatureControls();
  }

  @override
  void dispose() {
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadFeatureControls() async {
    setState(() => _isLoading = true);

    try {
      final response = await _adminService.getFeatureToggles();
      final participationFeeEnabled = response['participation_fees'] ?? false;

      // Get detailed configuration
      final detailsResponse = await SupabaseService.instance.client
          .from('platform_feature_controls')
          .select()
          .eq('feature_name', 'participation_fees')
          .maybeSingle();

      setState(() {
        _isGloballyEnabled = participationFeeEnabled;
        _enabledCountries = List<String>.from(
          detailsResponse?['enabled_countries'] ?? [],
        );
        _disabledCountries = List<String>.from(
          detailsResponse?['disabled_countries'] ?? [],
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load feature controls error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleGlobalFeature(bool value) async {
    setState(() => _isSaving = true);

    try {
      final success = await _adminService.updateFeatureToggle(
        featureName: 'participation_fees',
        isEnabled: value,
      );

      if (success) {
        setState(() => _isGloballyEnabled = value);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value
                    ? 'Participation fees enabled globally'
                    : 'Participation fees disabled globally',
              ),
              backgroundColor: AppTheme.accentLight,
            ),
          );
        }
        widget.onRefresh?.call();
      }
    } catch (e) {
      debugPrint('Toggle global feature error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updateCountryList(String countryCode, bool enable) async {
    setState(() => _isSaving = true);

    try {
      List<String> updatedEnabled = List.from(_enabledCountries);
      List<String> updatedDisabled = List.from(_disabledCountries);

      if (enable) {
        if (!updatedEnabled.contains(countryCode)) {
          updatedEnabled.add(countryCode);
        }
        updatedDisabled.remove(countryCode);
      } else {
        if (!updatedDisabled.contains(countryCode)) {
          updatedDisabled.add(countryCode);
        }
        updatedEnabled.remove(countryCode);
      }

      await SupabaseService.instance.client
          .from('platform_feature_controls')
          .update({
            'enabled_countries': updatedEnabled,
            'disabled_countries': updatedDisabled,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('feature_name', 'participation_fees');

      setState(() {
        _enabledCountries = updatedEnabled;
        _disabledCountries = updatedDisabled;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enable ? 'Enabled for $countryCode' : 'Disabled for $countryCode',
            ),
            backgroundColor: AppTheme.accentLight,
          ),
        );
      }
    } catch (e) {
      debugPrint('Update country list error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.accentLight),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlobalToggle(),
          SizedBox(height: 3.h),
          if (_isGloballyEnabled) ...[
            _buildCountryControls(),
            SizedBox(height: 3.h),
            _buildCountryList(),
          ],
        ],
      ),
    );
  }

  Widget _buildGlobalToggle() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: AppTheme.primaryLight, size: 8.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Participation Fees',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Enable or disable participation fees globally',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isGloballyEnabled,
                onChanged: _isSaving ? null : _toggleGlobalFeature,
                activeThumbColor: AppTheme.accentLight,
              ),
            ],
          ),
          if (_isGloballyEnabled) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.accentLight.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.accentLight,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Participation fees are now enabled. Configure country-specific settings below.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.accentLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountryControls() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Country-Specific Controls',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Enable or disable participation fees for specific countries',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 2.h),
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _commonCountries.map((country) {
              final isEnabled = _enabledCountries.contains(country['code']);
              final isDisabled = _disabledCountries.contains(country['code']);

              return InkWell(
                onTap: _isSaving
                    ? null
                    : () => _updateCountryList(country['code']!, !isEnabled),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppTheme.accentLight.withAlpha(26)
                        : isDisabled
                        ? AppTheme.errorLight.withAlpha(26)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: isEnabled
                          ? AppTheme.accentLight
                          : isDisabled
                          ? AppTheme.errorLight
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        country['code']!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: isEnabled
                              ? AppTheme.accentLight
                              : isDisabled
                              ? AppTheme.errorLight
                              : Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Icon(
                        isEnabled
                            ? Icons.check_circle
                            : isDisabled
                            ? Icons.cancel
                            : Icons.circle_outlined,
                        size: 4.w,
                        color: isEnabled
                            ? AppTheme.accentLight
                            : isDisabled
                            ? AppTheme.errorLight
                            : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryList() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Configuration',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (_enabledCountries.isEmpty && _disabledCountries.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No country-specific restrictions.\nFees enabled for all countries.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else ...[
            if (_enabledCountries.isNotEmpty) ...[
              Text(
                'Enabled Countries (${_enabledCountries.length})',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentLight,
                ),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: _enabledCountries.map((code) {
                  return Chip(
                    label: Text(code),
                    backgroundColor: AppTheme.accentLight.withAlpha(26),
                    deleteIcon: Icon(Icons.close, size: 4.w),
                    onDeleted: () => _updateCountryList(code, false),
                  );
                }).toList(),
              ),
              SizedBox(height: 2.h),
            ],
            if (_disabledCountries.isNotEmpty) ...[
              Text(
                'Disabled Countries (${_disabledCountries.length})',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorLight,
                ),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: _disabledCountries.map((code) {
                  return Chip(
                    label: Text(code),
                    backgroundColor: AppTheme.errorLight.withAlpha(26),
                    deleteIcon: Icon(Icons.close, size: 4.w),
                    onDeleted: () => _updateCountryList(code, true),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
