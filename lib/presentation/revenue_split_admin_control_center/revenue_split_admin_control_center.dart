import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/revenue_split_admin_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../theme/app_theme.dart';

/// Revenue Split Admin Control Screen
/// Complete admin management system for creator revenue splits
class RevenueSplitAdminControlScreen extends StatefulWidget {
  const RevenueSplitAdminControlScreen({super.key});

  @override
  State<RevenueSplitAdminControlScreen> createState() =>
      _RevenueSplitAdminControlScreenState();
}

class _RevenueSplitAdminControlScreenState
    extends State<RevenueSplitAdminControlScreen>
    with SingleTickerProviderStateMixin {
  final RevenueSplitAdminService _splitService =
      RevenueSplitAdminService.instance;

  late TabController _tabController;
  Map<String, dynamic>? _globalSplit;
  List<Map<String, dynamic>> _campaigns = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  double _simSampleRevenue = 10000;
  double _simCreatorPercent = 70;

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

    final globalSplit = await _splitService.getGlobalSplit();
    final campaigns = await _splitService.getActiveCampaigns();
    final statistics = await _splitService.getSplitStatistics();

    if (mounted) {
      setState(() {
        _globalSplit = globalSplit;
        _campaigns = campaigns;
        _statistics = statistics;
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditGlobalSplitDialog() async {
    if (_globalSplit == null) return;

    final creatorPercentage = _globalSplit!['creator_percentage'] as int;
    double sliderValue = creatorPercentage.toDouble();
    final reasonController = TextEditingController();
    DateTime effectiveDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Edit Global Split',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creator Percentage',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.accentLight,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: AppTheme.accentLight,
                    overlayColor: AppTheme.accentLight.withValues(alpha: 0.2),
                    valueIndicatorColor: AppTheme.accentLight,
                  ),
                  child: Slider(
                    value: sliderValue,
                    min: 50,
                    max: 90,
                    divisions: 40,
                    label: '${sliderValue.toInt()}%',
                    onChanged: (value) {
                      setDialogState(() => sliderValue = value);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Creator: ${sliderValue.toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Platform: ${100 - sliderValue.toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Effective Date',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: effectiveDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => effectiveDate = picked);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${effectiveDate.year}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(fontSize: 12.sp),
                        ),
                        Icon(Icons.calendar_today, size: 16.sp),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason for Change',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Impact Preview',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '\$100 transaction: Creator gets \$${(100 * sliderValue / 100).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                      Text(
                        '\$1000 transaction: Creator gets \$${(1000 * sliderValue / 100).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Affected creators: ${_statistics['total_creators'] ?? 0}',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLight,
              ),
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final success = await _splitService.updateGlobalSplit(
        creatorPercentage: sliderValue.toInt(),
        platformPercentage: 100 - sliderValue.toInt(),
        effectiveDate: effectiveDate,
        reason: reasonController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Global split updated successfully'
                  : 'Failed to update global split',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'RevenueSplitAdminControlScreen',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Revenue Split Admin',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: 20.sp),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? ShimmerSkeletonLoader(child: SkeletonDashboard())
            : Column(
                children: [
                  _buildStatisticsHeader(),
                  SizedBox(height: 2.h),
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.accentLight,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: AppTheme.accentLight,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Global Split'),
                        Tab(text: 'Campaigns'),
                        Tab(text: 'Simulator'),
                        Tab(text: 'Audit Log'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGlobalSplitTab(),
                        _buildCampaignsTab(),
                        _buildSimulatorTab(),
                        _buildAuditLogTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatisticsHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: AppTheme.accentLight.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Global Split',
              '${_statistics['current_global_split'] ?? 70}%',
              Icons.pie_chart,
              Colors.blue,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildStatCard(
              'Active Campaigns',
              '${_statistics['active_campaigns_count'] ?? 0}',
              Icons.campaign,
              Colors.green,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildStatCard(
              'Total Creators',
              '${_statistics['total_creators'] ?? 0}',
              Icons.people,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
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
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSplitTab() {
    if (_globalSplit == null) {
      return Center(child: Text('No global split configured'));
    }

    final creatorPercentage = _globalSplit!['creator_percentage'] as int;
    final platformPercentage = _globalSplit!['platform_percentage'] as int;
    final effectiveDate = _globalSplit!['effective_date'] as String;
    final reason = _globalSplit!['reason'] as String? ?? '';

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Active Split',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$creatorPercentage%',
                              style: GoogleFonts.inter(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Creator',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '/',
                        style: GoogleFonts.inter(
                          fontSize: 24.sp,
                          color: Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$platformPercentage%',
                              style: GoogleFonts.inter(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              'Platform',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Divider(),
                  SizedBox(height: 1.h),
                  _buildInfoRow('Effective Since', effectiveDate),
                  _buildInfoRow('Reason', reason),
                  _buildInfoRow(
                    'Affected Creators',
                    '${_statistics['total_creators'] ?? 0}',
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showEditGlobalSplitDialog,
                      icon: Icon(Icons.edit, size: 16.sp),
                      label: Text('Edit Global Split'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentLight,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _campaigns.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateRevenueCampaignDialog(context),
              icon: Icon(Icons.add, size: 16.sp),
              label: Text('Create New Campaign'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLight,
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
            ),
          );
        }

        final campaign = _campaigns[index - 1];
        return _buildCampaignCard(campaign);
      },
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final campaignName = campaign['campaign_name'] as String;
    final status = campaign['status'] as String;
    final creatorSplit = campaign['creator_split_percentage'] as int;
    final enrolledCount = campaign['enrolled_creator_count'] as int? ?? 0;

    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'scheduled':
        statusColor = Colors.blue;
        break;
      case 'paused':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    campaignName,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Creator Split: $creatorSplit%',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Enrolled Creators: $enrolledCount',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatorTab() {
    final creatorPct = _simCreatorPercent.round().clamp(50, 95);
    final platformPct = 100 - creatorPct;
    final creatorShare = _simSampleRevenue * creatorPct / 100.0;
    final platformShare = _simSampleRevenue - creatorShare;

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Split simulator (preview)',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Adjust sample gross revenue and creator share. This does not write to the database.',
          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 2.h),
        Text(
          'Sample gross: \$${_simSampleRevenue.toStringAsFixed(0)}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        Slider(
          value: _simSampleRevenue.clamp(100, 2000000),
          min: 100,
          max: 2000000,
          divisions: 100,
          label: '\$${_simSampleRevenue.toStringAsFixed(0)}',
          onChanged: (v) => setState(() => _simSampleRevenue = v),
        ),
        SizedBox(height: 1.h),
        Text(
          'Creator $creatorPct% / Platform $platformPct%',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        Slider(
          value: _simCreatorPercent.clamp(50, 95),
          min: 50,
          max: 95,
          divisions: 45,
          label: '$creatorPct%',
          onChanged: (v) => setState(() => _simCreatorPercent = v),
        ),
        SizedBox(height: 2.h),
        _buildInfoRow('Creator share', '\$${creatorShare.toStringAsFixed(2)}'),
        _buildInfoRow('Platform share', '\$${platformShare.toStringAsFixed(2)}'),
        SizedBox(height: 2.h),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context, rootNavigator: true)
              .pushNamed(AppRoutes.electionCreationStudio),
          icon: const Icon(Icons.how_to_vote),
          label: const Text('Open election creation (related flow)'),
        ),
      ],
    );
  }

  Future<void> _showCreateRevenueCampaignDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var split = 70;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Create revenue split campaign'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Campaign name'),
                    ),
                    SizedBox(height: 1.h),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text('Creator split: $split%'),
                    Slider(
                      value: split.toDouble(),
                      min: 50,
                      max: 95,
                      divisions: 45,
                      label: '$split%',
                      onChanged: (v) => setLocal(() => split = v.round()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a campaign name')),
                      );
                      return;
                    }
                    try {
                      final id = await _splitService.createCampaign(
                        campaignName: name,
                        campaignDescription: descCtrl.text.trim().isEmpty
                            ? 'Revenue split campaign'
                            : descCtrl.text.trim(),
                        campaignType: 'standard',
                        creatorSplitPercentage: split,
                        eligibilityCriteria: const {},
                        startDate: DateTime.now(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!context.mounted) return;
                      if (id != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Campaign created: $id')),
                        );
                        await _loadData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not create campaign'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Create failed: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      descCtrl.dispose();
    });
  }

  Widget _buildAuditLogTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _splitService.getAuditLog(limit: 50),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final auditLogs = snapshot.data!;

        if (auditLogs.isEmpty) {
          return Center(child: Text('No audit logs found'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(4.w),
          itemCount: auditLogs.length,
          itemBuilder: (context, index) {
            final log = auditLogs[index];
            final actionType = log['action_type'] as String;
            final timestamp = log['timestamp'] as String;

            return Card(
              margin: EdgeInsets.only(bottom: 2.h),
              child: ListTile(
                leading: Icon(
                  _getAuditIcon(actionType),
                  color: AppTheme.accentLight,
                ),
                title: Text(
                  actionType.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  DateTime.parse(timestamp).toString(),
                  style: GoogleFonts.inter(fontSize: 10.sp),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getAuditIcon(String actionType) {
    switch (actionType) {
      case 'config_change':
        return Icons.settings;
      case 'campaign_create':
        return Icons.add_circle;
      case 'campaign_modify':
        return Icons.edit;
      case 'campaign_end':
        return Icons.stop_circle;
      default:
        return Icons.info;
    }
  }
}
