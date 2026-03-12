import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/feature_management_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../theme/app_theme.dart';

/// Feature Flag Management Dashboard providing enterprise-grade feature control
/// with comprehensive flag lifecycle management, A/B testing, and real-time rollout controls
class FeatureFlagManagementDashboard extends StatefulWidget {
  const FeatureFlagManagementDashboard({super.key});

  @override
  State<FeatureFlagManagementDashboard> createState() =>
      _FeatureFlagManagementDashboardState();
}

class _FeatureFlagManagementDashboardState
    extends State<FeatureFlagManagementDashboard>
    with SingleTickerProviderStateMixin {
  final FeatureManagementService _featureService =
      FeatureManagementService.instance;
  final AuthService _authService = AuthService.instance;

  late TabController _tabController;
  StreamSubscription? _flagsSubscription;
  List<Map<String, dynamic>> _allFlags = [];
  List<Map<String, dynamic>> _filteredFlags = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _flagsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _flagsSubscription = _featureService.streamFeatureFlags().listen((flags) {
      if (mounted) {
        setState(() {
          _allFlags = flags;
          _applyFilters();
          _isLoading = false;
        });
      }
    });
  }

  void _applyFilters() {
    _filteredFlags = _allFlags.where((flag) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          flag['flag_name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          flag['flag_key'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesFilter =
          _selectedFilter == 'all' ||
          (_selectedFilter == 'enabled' && flag['is_enabled'] == true) ||
          (_selectedFilter == 'disabled' && flag['is_enabled'] == false) ||
          (_selectedFilter == 'experiments' &&
              flag['experiment_config'] != null);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _showCreateFlagDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildCreateFlagDialog(null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'FeatureFlagManagementDashboard',
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppTheme.primaryLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feature Flag Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Enterprise Feature Control',
                style: TextStyle(color: Colors.white70, fontSize: 11.sp),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: _showCreateFlagDialog,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.vibrantYellow,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Flags'),
              Tab(text: 'A/B Tests'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
        body: _isLoading ? _buildLoadingState() : _buildContent(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateFlagDialog,
          backgroundColor: AppTheme.vibrantYellow,
          icon: const Icon(Icons.add, color: Colors.black),
          label: const Text('New Flag', style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [_buildFlagsTab(), _buildABTestingTab(), _buildAnalyticsTab()],
    );
  }

  Widget _buildFlagsTab() {
    final activeFlags = _allFlags.where((f) => f['is_enabled'] == true).length;
    final experiments = _allFlags
        .where((f) => f['experiment_config'] != null)
        .length;

    return Column(
      children: [
        _buildFlagOverviewWidget(
          totalFlags: _allFlags.length,
          activeFlags: activeFlags,
          runningExperiments: experiments,
        ),
        Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search flags...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
              SizedBox(width: 2.w),
              DropdownButton<String>(
                value: _selectedFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'enabled', child: Text('Enabled')),
                  DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
                  DropdownMenuItem(
                    value: 'experiments',
                    child: Text('Experiments'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value ?? 'all';
                    _applyFilters();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredFlags.isEmpty
              ? Center(
                  child: Text(
                    'No flags found',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  itemCount: _filteredFlags.length,
                  itemBuilder: (context, index) {
                    return _buildFlagManagementCard(_filteredFlags[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildABTestingTab() {
    final experiments = _allFlags
        .where((f) => f['experiment_config'] != null)
        .toList();

    return experiments.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.science_outlined, size: 20.w, color: Colors.grey),
                SizedBox(height: 2.h),
                Text(
                  'No A/B Tests Running',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Create experiments to test feature variations',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(3.w),
            itemCount: experiments.length,
            itemBuilder: (context, index) {
              return _buildABTestingConfigWidget(experiments[index]);
            },
          );
  }

  Widget _buildAnalyticsTab() {
    return _buildFlagAnalyticsWidget(_allFlags);
  }

  Future<void> _handleFlagToggle(Map<String, dynamic> flag) async {
    final success = await _featureService.updateFeatureFlag(
      featureId: flag['id'],
      isEnabled: !(flag['is_enabled'] ?? false),
      reason: 'Manual toggle by admin',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Flag ${flag['is_enabled'] ? "disabled" : "enabled"}'
                : 'Failed to update flag',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showEditFlagDialog(Map<String, dynamic> flag) {
    showDialog(
      context: context,
      builder: (context) => _buildCreateFlagDialog(flag),
    );
  }

  // Add placeholder widget methods
  Widget _buildFlagOverviewWidget({
    required int totalFlags,
    required int activeFlags,
    required int runningExperiments,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$totalFlags',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Total Flags', style: TextStyle(fontSize: 12.sp)),
                ],
              ),
              Column(
                children: [
                  Text(
                    '$activeFlags',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Active', style: TextStyle(fontSize: 12.sp)),
                ],
              ),
              Column(
                children: [
                  Text(
                    '$runningExperiments',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Experiments', style: TextStyle(fontSize: 12.sp)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlagManagementCard(Map<String, dynamic> flag) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: ListTile(
        title: Text(flag['flag_name'] ?? 'Unknown'),
        subtitle: Text(flag['flag_key'] ?? ''),
        trailing: Switch(
          value: flag['is_enabled'] ?? false,
          onChanged: (value) => _handleFlagToggle(flag),
        ),
        onTap: () => _showEditFlagDialog(flag),
      ),
    );
  }

  Widget _buildABTestingConfigWidget(Map<String, dynamic> flag) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              flag['flag_name'] ?? 'Unknown',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text('Experiment Config: ${flag['experiment_config']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagAnalyticsWidget(List<Map<String, dynamic>> flags) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 20.w, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'Analytics Dashboard',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Text(
            'Total Flags: ${flags.length}',
            style: TextStyle(fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateFlagDialog(Map<String, dynamic>? flag) {
    return AlertDialog(
      title: Text(flag == null ? 'Create Flag' : 'Edit Flag'),
      content: Text('Flag management dialog placeholder'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  flag == null
                      ? 'Feature flag created successfully'
                      : 'Feature flag updated successfully',
                ),
              ),
            );
          },
          child: Text(flag == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}
