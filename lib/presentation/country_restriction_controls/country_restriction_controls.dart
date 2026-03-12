import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/admin_control_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class CountryRestrictionControls extends StatefulWidget {
  const CountryRestrictionControls({super.key});

  @override
  State<CountryRestrictionControls> createState() =>
      _CountryRestrictionControlsState();
}

class _CountryRestrictionControlsState extends State<CountryRestrictionControls>
    with SingleTickerProviderStateMixin {
  final _adminService = AdminControlService.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _violationLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'All';

  final Map<String, List<String>> _regions = {
    'North America': ['US', 'CA', 'MX'],
    'Europe': ['GB', 'DE', 'FR', 'IT', 'ES'],
    'Asia': ['JP', 'CN', 'IN', 'SG'],
    'Middle East': ['AE', 'SA'],
    'Africa': ['ZA', 'NG', 'KE'],
    'Oceania': ['AU', 'NZ'],
    'South America': ['BR'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCountries();
    _loadViolationLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoading = true);
    try {
      final countries = await _adminService.getAllCountryRestrictions();
      setState(() {
        _countries = countries;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading countries: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadViolationLogs() async {
    try {
      final logs = await _adminService.getViolationLogs(limit: 50);
      setState(() => _violationLogs = logs);
    } catch (e) {
      print('Error loading violation logs: $e');
    }
  }

  Future<void> _updateCountryStatus(
    String countryCode,
    String countryName,
    bool newStatus,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          newStatus ? 'Allow Country?' : 'Restrict Country?',
          style: TextStyle(fontSize: 16.sp),
        ),
        content: Text(
          '${newStatus ? "Allow" : "Restrict"} access from $countryName ($countryCode)?\n\nThis will affect all users from this country immediately.',
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.red,
            ),
            child: Text(newStatus ? 'Allow' : 'Restrict'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _adminService.updateCountryRestriction(
        countryCode: countryCode,
        isAllowed: newStatus,
        changeReason: 'Manual update from admin panel',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$countryName ${newStatus ? "allowed" : "restricted"} successfully',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
        _loadCountries();
      }
    }
  }

  Future<void> _bulkUpdateRegion(String region, bool isAllowed) async {
    final countryCodes = _regions[region] ?? [];
    if (countryCodes.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Bulk ${isAllowed ? "Allow" : "Restrict"} Region?',
          style: TextStyle(fontSize: 16.sp),
        ),
        content: Text(
          '${isAllowed ? "Allow" : "Restrict"} all countries in $region?\n\nCountries: ${countryCodes.join(", ")}',
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAllowed ? Colors.green : Colors.red,
            ),
            child: Text(isAllowed ? 'Allow All' : 'Restrict All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _adminService.bulkUpdateCountries(
        countryCodes: countryCodes,
        isAllowed: isAllowed,
        changeReason: 'Bulk $region region update',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$region region updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCountries();
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCountries {
    return _countries.where((country) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (country['country_name'] as String? ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (country['country_code'] as String? ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesFilter =
          _filterStatus == 'All' ||
          (_filterStatus == 'Allowed' && country['is_allowed'] == true) ||
          (_filterStatus == 'Restricted' && country['is_allowed'] == false);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CountryRestrictionControls',
      onRetry: () {
        _loadCountries();
        _loadViolationLogs();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Country Restriction Controls',
            variant: CustomAppBarVariant.standard,
            actions: [
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: Theme.of(context).appBarTheme.foregroundColor!,
                  size: 24,
                ),
                onPressed: () {
                  _loadCountries();
                  _loadViolationLogs();
                },
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Country Management'),
                      Tab(text: 'Regional Actions'),
                      Tab(text: 'Violation Logs'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCountryManagementTab(Theme.of(context)),
                        _buildRegionalActionsTab(Theme.of(context)),
                        _buildViolationLogsTab(Theme.of(context)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCountryManagementTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadCountries,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsHeader(theme),
            SizedBox(height: 3.h),
            _buildSearchBar(theme),
            SizedBox(height: 2.h),
            _buildFilterChips(theme),
            SizedBox(height: 3.h),
            _buildCountryList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(ThemeData theme) {
    final totalCountries = _countries.length;
    final allowedCountries = _countries
        .where((c) => c['is_allowed'] == true)
        .length;
    final restrictedCountries = totalCountries - allowedCountries;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                theme,
                'Total',
                totalCountries.toString(),
                Icons.public,
                Colors.blue,
              ),
            ),
            Container(width: 1, height: 50, color: theme.dividerColor),
            Expanded(
              child: _buildStatItem(
                theme,
                'Allowed',
                allowedCountries.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            Container(width: 1, height: 50, color: theme.dividerColor),
            Expanded(
              child: _buildStatItem(
                theme,
                'Restricted',
                restrictedCountries.toString(),
                Icons.block,
                Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 1.h),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search countries...',
        prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: theme.cardColor,
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    final filters = ['All', 'Allowed', 'Restricted'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filterStatus == filter;

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _filterStatus = filter);
              },
              backgroundColor: theme.cardColor,
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountryList(ThemeData theme) {
    final filteredCountries = _filteredCountries;

    if (filteredCountries.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: theme.disabledColor),
            SizedBox(height: 2.h),
            Text(
              'No countries found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Countries (${filteredCountries.length})',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        ...filteredCountries.map(
          (country) => _buildCountryCard(theme, country),
        ),
      ],
    );
  }

  Widget _buildCountryCard(ThemeData theme, Map<String, dynamic> country) {
    final countryCode = country['country_code'] as String? ?? 'XX';
    final countryName = country['country_name'] as String? ?? 'Unknown';
    final isAllowed = country['is_allowed'] as bool? ?? false;
    final feeZone = country['fee_zone'] as int? ?? 1;
    final complianceLevel =
        country['compliance_level'] as String? ?? 'moderate';
    final biometricAllowed = country['biometric_allowed'] as bool? ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isAllowed
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      countryCode,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isAllowed ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countryName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          _buildInfoChip(
                            theme,
                            'Zone $feeZone',
                            Icons.attach_money,
                            Colors.blue,
                          ),
                          SizedBox(width: 2.w),
                          _buildInfoChip(
                            theme,
                            complianceLevel.toUpperCase(),
                            Icons.security,
                            _getComplianceColor(complianceLevel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isAllowed,
                  onChanged: (_) => _updateCountryStatus(
                    countryCode,
                    countryName,
                    !isAllowed,
                  ),
                  activeThumbColor: Colors.green,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(
                  biometricAllowed ? Icons.fingerprint : Icons.help_outline,
                  size: 16,
                  color: biometricAllowed ? Colors.green : Colors.red,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Biometric: ${biometricAllowed ? "Allowed" : "Restricted"}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getComplianceColor(String level) {
    switch (level.toLowerCase()) {
      case 'strict':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'permissive':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRegionalActionsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulk Regional Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Apply restrictions or allowances to entire regions at once',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 3.h),
          ..._regions.entries.map(
            (entry) => _buildRegionCard(theme, entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(ThemeData theme, String region, List<String> codes) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              region,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Countries: ${codes.join(", ")}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _bulkUpdateRegion(region, true),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Allow All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _bulkUpdateRegion(region, false),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Restrict All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationLogsTab(ThemeData theme) {
    if (_violationLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No violations detected',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.green),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadViolationLogs,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _violationLogs.length,
        itemBuilder: (context, index) {
          final log = _violationLogs[index];
          return _buildViolationLogCard(theme, log);
        },
      ),
    );
  }

  Widget _buildViolationLogCard(ThemeData theme, Map<String, dynamic> log) {
    final countryCode = log['country_code'] as String? ?? 'XX';
    final violationType = log['violation_type'] as String? ?? 'Unknown';
    final vpnDetected = log['vpn_detected'] as bool? ?? false;
    final ipAddress = log['ip_address'] as String? ?? 'Unknown';
    final createdAt = DateTime.tryParse(log['created_at'] as String? ?? '');

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Icon(
          vpnDetected ? Icons.vpn_lock : Icons.warning,
          color: Colors.red,
        ),
        title: Text(
          '$countryCode - $violationType',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IP: $ipAddress', style: TextStyle(fontSize: 11.sp)),
            if (vpnDetected)
              Text(
                'VPN Detected',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (createdAt != null)
              Text(
                _formatDateTime(createdAt),
                style: TextStyle(fontSize: 10.sp),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
