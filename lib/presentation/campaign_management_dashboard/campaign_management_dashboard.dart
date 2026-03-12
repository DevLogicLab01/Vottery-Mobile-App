import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../constants/vottery_ads_constants.dart';
import '../../services/auth_service.dart';
import '../../services/sponsored_elections_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/campaign_card_widget.dart';
import './widgets/campaign_stats_header_widget.dart';

class CampaignManagementDashboard extends StatefulWidget {
  const CampaignManagementDashboard({super.key});

  @override
  State<CampaignManagementDashboard> createState() =>
      _CampaignManagementDashboardState();
}

class _CampaignManagementDashboardState
    extends State<CampaignManagementDashboard> {
  final SponsoredElectionsService _service = SponsoredElectionsService.instance;
  final AuthService _auth = AuthService.instance;

  List<Map<String, dynamic>> _campaigns = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  RealtimeChannel? _realtimeChannel;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
    _setupAutoRefresh();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadCampaigns(silent: true);
    });
  }

  void _setupRealtimeSubscription() {
    try {
      _realtimeChannel = Supabase.instance.client
          .channel('sponsored_elections_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'sponsored_elections',
            callback: (payload) {
              _loadCampaigns(silent: true);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime subscription error: $e');
    }
  }

  Future<void> _loadCampaigns({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.id;
      List<Map<String, dynamic>> campaigns;
      if (userId != null) {
        campaigns = await _service.getBrandSponsoredElections(brandId: userId);
      } else {
        campaigns = await _service.getActiveSponsoredElections();
      }
      if (mounted) {
        setState(() {
          _campaigns = campaigns;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCampaigns {
    if (_filterStatus == 'all') return _campaigns;
    return _campaigns
        .where(
          (c) => (c['status'] as String? ?? '').toLowerCase() == _filterStatus,
        )
        .toList();
  }

  int get _activeCampaigns => _campaigns
      .where((c) => (c['status'] as String? ?? '').toUpperCase() == 'ACTIVE')
      .length;

  int get _totalReach => _campaigns.fold(
    0,
    (sum, c) =>
        sum +
        ((c['reach_count'] ?? c['target_participants'] ?? 0) as num).toInt(),
  );

  double get _avgCpe {
    if (_campaigns.isEmpty) return 0.0;
    final total = _campaigns.fold(
      0.0,
      (sum, c) =>
          sum +
          ((c['cpe_value'] ?? c['cost_per_participant'] ?? 0.0) as num)
              .toDouble(),
    );
    return total / _campaigns.length;
  }

  Future<void> _handlePause(Map<String, dynamic> campaign) async {
    final id = campaign['id'] as String?;
    if (id == null) return;
    final currentStatus = (campaign['status'] as String? ?? 'ACTIVE').toUpperCase();
    final newStatus = currentStatus == 'PAUSED' ? 'ACTIVE' : 'PAUSED';
    try {
      await Supabase.instance.client
          .from('sponsored_elections')
          .update({'status': newStatus})
          .eq('id', id);
      _loadCampaigns(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Campaign ${newStatus == 'PAUSED' ? 'paused' : 'resumed'}',
            ),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleArchive(Map<String, dynamic> campaign) async {
    final id = campaign['id'] as String?;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Campaign'),
        content: const Text(
          'Are you sure you want to archive this campaign? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client
          .from('sponsored_elections')
          .update({'status': 'ended'})
          .eq('id', id);
      _loadCampaigns(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign archived'),
            backgroundColor: Color(0xFF6B7280),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _handleEdit(Map<String, dynamic> campaign) {
    Navigator.pushNamed(
      context,
      AppRoutes.participatoryAdsStudio,
      arguments: campaign,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ErrorBoundaryWrapper(
      screenName: 'CampaignManagementDashboard',
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Campaign Management',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadCampaigns(),
              tooltip: 'Refresh',
            ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => Navigator.pushNamed(
                  context,
                  VotteryAdsConstants.votteryAdsStudioRoute,
                ),
                tooltip: 'New Campaign',
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadCampaigns(),
          child: Column(
            children: [
              SizedBox(height: 1.h),
              CampaignStatsHeaderWidget(
                activeCampaigns: _activeCampaigns,
                totalReach: _totalReach,
                avgCpe: _avgCpe,
                isLoading: _isLoading,
              ),
              SizedBox(height: 1.h),
              // Filter chips
              SizedBox(
                height: 5.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _filterStatus == 'all',
                      onTap: () => setState(() => _filterStatus = 'all'),
                    ),
                    SizedBox(width: 2.w),
                    _FilterChip(
                      label: 'Active',
                      isSelected: _filterStatus == 'active',
                      color: const Color(0xFF22C55E),
                      onTap: () => setState(() => _filterStatus = 'active'),
                    ),
                    SizedBox(width: 2.w),
                    _FilterChip(
                      label: 'Paused',
                      isSelected: _filterStatus == 'paused',
                      color: const Color(0xFFF59E0B),
                      onTap: () => setState(() => _filterStatus = 'paused'),
                    ),
                    SizedBox(width: 2.w),
                    _FilterChip(
                      label: 'Ended',
                      isSelected: _filterStatus == 'ended',
                      color: const Color(0xFF6B7280),
                      onTap: () => setState(() => _filterStatus = 'ended'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 1.h),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.participatoryAdsStudio),
          icon: const Icon(Icons.add),
          label: const Text('New Campaign'),
          backgroundColor: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: ShimmerSkeletonLoader(
            child: Container(
              width: double.infinity,
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 2.h),
            Text(
              'Failed to load campaigns',
              style: GoogleFonts.inter(fontSize: 14.sp),
            ),
            SizedBox(height: 1.h),
            ElevatedButton(
              onPressed: () => _loadCampaigns(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_filteredCampaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 15.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 2.h),
            Text(
              _filterStatus == 'all'
                  ? 'No campaigns yet'
                  : 'No $_filterStatus campaigns',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 1.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.participatoryAdsStudio,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create Campaign'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _filteredCampaigns.length,
      itemBuilder: (context, index) {
        final campaign = _filteredCampaigns[index];
        return CampaignCardWidget(
          campaign: campaign,
          onPause: () => _handlePause(campaign),
          onEdit: () => _handleEdit(campaign),
          onArchive: () => _handleArchive(campaign),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF6366F1);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withAlpha(20),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withAlpha(80),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : chipColor,
          ),
        ),
      ),
    );
  }
}