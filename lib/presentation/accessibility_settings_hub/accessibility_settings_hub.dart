import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/accessibility_preferences_service.dart';
import '../../services/offline_sync_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/font_scaling_widget.dart';
import './widgets/offline_sync_status_widget.dart';
import './widgets/connectivity_banner_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';

class AccessibilitySettingsHub extends StatefulWidget {
  const AccessibilitySettingsHub({super.key});

  @override
  State<AccessibilitySettingsHub> createState() =>
      _AccessibilitySettingsHubState();
}

class _AccessibilitySettingsHubState extends State<AccessibilitySettingsHub> {
  bool _isOnline = true;
  int _pendingVotesCount = 0;
  double _currentFontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToConnectivity();
    AccessibilityPreferencesService.instance.trackAccessibilitySettingsOpened();
  }

  Future<void> _loadData() async {
    final fontScale = AccessibilityPreferencesService.instance.fontScaleFactor;
    final isOnline = await OfflineSyncService.instance.isOnline();
    final pendingCount = await OfflineSyncService.instance
        .getPendingVotesCount();

    if (mounted) {
      setState(() {
        _currentFontScale = fontScale;
        _isOnline = isOnline;
        _pendingVotesCount = pendingCount;
      });
    }
  }

  void _listenToConnectivity() {
    OfflineSyncService.instance.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
        if (isOnline) {
          _loadData();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'AccessibilitySettingsHub',
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Accessibility Settings',
            variant: CustomAppBarVariant.withBack,
          ),
        ),
        body: Column(
          children: [
            // Connectivity banner
            if (!_isOnline || _pendingVotesCount > 0)
              ConnectivityBannerWidget(
                isOnline: _isOnline,
                pendingCount: _pendingVotesCount,
                onSyncPressed: () async {
                  await OfflineSyncService.instance.syncPendingVotes();
                  _loadData();
                },
              ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Accessibility status overview
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.accessibility_new,
                                  color: theme.colorScheme.primary,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'Accessibility Status',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            _buildStatusRow(
                              'Font Size',
                              '${(_currentFontScale * 100).toInt()}%',
                              Icons.text_fields,
                            ),
                            _buildStatusRow(
                              'Sync Status',
                              _isOnline ? 'Online' : 'Offline',
                              _isOnline ? Icons.cloud_done : Icons.cloud_off,
                            ),
                            _buildStatusRow(
                              'Pending Votes',
                              '$_pendingVotesCount',
                              Icons.pending_actions,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Font Size Controls
                    Text(
                      'Font Size Controls',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    FontScalingWidget(
                      currentScale: _currentFontScale,
                      onScaleChanged: (scale) {
                        setState(() => _currentFontScale = scale);
                      },
                    ),
                    SizedBox(height: 2.h),

                    // Offline Mode Management
                    Text(
                      'Offline Mode Management',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    OfflineSyncStatusWidget(
                      isOnline: _isOnline,
                      pendingCount: _pendingVotesCount,
                      onRefresh: _loadData,
                    ),
                    SizedBox(height: 2.h),

                    // Visual Preferences
                    Text(
                      'Visual Preferences',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(
                              'High Contrast',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            subtitle: Text(
                              'Increase contrast for better visibility',
                              style: TextStyle(fontSize: 10.sp),
                            ),
                            value: false,
                            onChanged: (value) {
                              // TODO: Implement high contrast mode
                            },
                          ),
                          Divider(height: 1),
                          SwitchListTile(
                            title: Text(
                              'Reduced Motion',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            subtitle: Text(
                              'Minimize animations and transitions',
                              style: TextStyle(fontSize: 10.sp),
                            ),
                            value: false,
                            onChanged: (value) {
                              // TODO: Implement reduced motion
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: Colors.grey[600]),
          SizedBox(width: 2.w),
          Text(
            '$label:',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
