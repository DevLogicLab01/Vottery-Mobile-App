import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/country_biometric_compliance_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/compliance_statistics_header_widget.dart';
import './widgets/country_biometric_card_widget.dart';
import './widgets/gdpr_auto_disable_panel_widget.dart';
import './widgets/compliance_audit_log_widget.dart';
import './widgets/regional_adoption_chart_widget.dart';
import './widgets/override_management_dialog_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Country Biometric Compliance Dashboard
/// Manages per-country biometric authentication controls with automated GDPR compliance
class CountryBiometricComplianceDashboard extends StatefulWidget {
  const CountryBiometricComplianceDashboard({super.key});

  @override
  State<CountryBiometricComplianceDashboard> createState() =>
      _CountryBiometricComplianceDashboardState();
}

class _CountryBiometricComplianceDashboardState
    extends State<CountryBiometricComplianceDashboard>
    with SingleTickerProviderStateMixin {
  final _complianceService = CountryBiometricComplianceService.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _countries = [];
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> _regionalAdoption = {};
  List<Map<String, dynamic>> _auditLog = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final countries = await _complianceService.getAllCountrySettings();
      final stats = await _complianceService.getComplianceStatistics();
      final adoption = await _complianceService.getBiometricAdoptionByRegion();
      final audit = await _complianceService.getComplianceAuditLog(limit: 50);

      setState(() {
        _countries = countries;
        _statistics = stats;
        _regionalAdoption = adoption;
        _auditLog = audit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CountryBiometricComplianceDashboard',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Country Biometric Compliance',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              onPressed: _loadData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  ComplianceStatisticsHeaderWidget(statistics: _statistics),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCountryMatrixTab(),
                        _buildGDPRComplianceTab(),
                        _buildRegionalAnalyticsTab(),
                        _buildAuditLogTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'Country Matrix'),
          Tab(text: 'GDPR Compliance'),
          Tab(text: 'Regional Analytics'),
          Tab(text: 'Audit Log'),
        ],
      ),
    );
  }

  Widget _buildCountryMatrixTab() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(child: _buildCountryList()),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search countries...',
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryLight),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: AppTheme.backgroundLight,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Text(
                'Filter:',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Enabled'),
                      _buildFilterChip('Disabled'),
                      _buildFilterChip('GDPR'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label;
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = selected ? label : 'All');
        },
        selectedColor: AppTheme.primaryLight.withAlpha(51),
        checkmarkColor: AppTheme.primaryLight,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryLight : Colors.grey.shade700,
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _buildCountryList() {
    final filteredCountries = _countries.where((country) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (country['country_name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (country['country_code'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesFilter =
          _filterStatus == 'All' ||
          (_filterStatus == 'Enabled' &&
              country['biometric_enabled'] == true) ||
          (_filterStatus == 'Disabled' &&
              country['biometric_enabled'] == false) ||
          (_filterStatus == 'GDPR' && country['is_gdpr_country'] == true);

      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredCountries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              size: 15.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 2.h),
            Text(
              'No countries found',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: filteredCountries.length,
      itemBuilder: (context, index) {
        return CountryBiometricCardWidget(
          country: filteredCountries[index],
          onToggle: (enabled) =>
              _handleCountryToggle(filteredCountries[index], enabled),
          onOverride: () => _showOverrideDialog(filteredCountries[index]),
        );
      },
    );
  }

  Widget _buildGDPRComplianceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GDPRAutoDisablePanelWidget(
            gdprCountries: _countries
                .where((c) => c['is_gdpr_country'] == true)
                .toList(),
          ),
          SizedBox(height: 3.h),
          _buildComplianceMonitoring(),
        ],
      ),
    );
  }

  Widget _buildComplianceMonitoring() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
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
              CustomIconWidget(
                iconName: 'monitor_heart',
                size: 6.w,
                color: AppTheme.accentLight,
              ),
              SizedBox(width: 2.w),
              Text(
                'Real-Time Compliance Monitoring',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildMonitoringItem(
            Icons.sync,
            'Real-time sync to elections',
            'Active',
            Colors.green,
          ),
          _buildMonitoringItem(
            Icons.security,
            'GDPR auto-disable',
            'Enforced',
            Colors.blue,
          ),
          _buildMonitoringItem(
            Icons.verified_user,
            'Compliance validation',
            'Passing',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringItem(
    IconData icon,
    String label,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 5.w, color: Colors.grey.shade600),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.sp)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11.sp,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RegionalAdoptionChartWidget(regionalData: _regionalAdoption),
          SizedBox(height: 3.h),
          _buildComplianceImpactAssessment(),
        ],
      ),
    );
  }

  Widget _buildComplianceImpactAssessment() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance Impact Assessment',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          _buildImpactMetric(
            'Total Countries Monitored',
            _statistics['total_countries']?.toString() ?? '0',
            Icons.public,
          ),
          _buildImpactMetric(
            'Biometric Enabled',
            _statistics['enabled_count']?.toString() ?? '0',
            Icons.fingerprint,
          ),
          _buildImpactMetric(
            'GDPR Compliance Rate',
            '${_statistics['compliance_rate'] ?? "0.0"}%',
            Icons.shield,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactMetric(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 5.w, color: AppTheme.primaryLight),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogTab() {
    return ComplianceAuditLogWidget(auditLog: _auditLog);
  }

  Future<void> _handleCountryToggle(
    Map<String, dynamic> country,
    bool enabled,
  ) async {
    final countryCode = country['country_code'] as String;
    final countryName = country['country_name'] as String;
    final isGdpr = country['is_gdpr_country'] as bool? ?? false;

    // Prevent enabling GDPR countries without override
    if (isGdpr && enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot enable biometric for GDPR country. Use Override function.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${enabled ? "Enable" : "Disable"} Biometric?',
          style: TextStyle(fontSize: 16.sp),
        ),
        content: Text(
          '${enabled ? "Enable" : "Disable"} biometric authentication for $countryName ($countryCode)?',
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? Colors.green : Colors.red,
            ),
            child: Text(enabled ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _complianceService.updateCountryBiometricSetting(
        countryCode: countryCode,
        enabled: enabled,
        justification: 'Manual update from compliance dashboard',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Biometric ${enabled ? "enabled" : "disabled"} for $countryName',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    }
  }

  Future<void> _showOverrideDialog(Map<String, dynamic> country) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => OverrideManagementDialogWidget(country: country),
    );

    if (result == true) {
      _loadData();
    }
  }
}
