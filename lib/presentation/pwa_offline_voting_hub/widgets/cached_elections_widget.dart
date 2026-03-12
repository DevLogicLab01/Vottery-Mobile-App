import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/offline_sync_service.dart';
import '../../../theme/app_theme.dart';

class CachedElectionsWidget extends StatefulWidget {
  final Function({
    required String electionId,
    required String electionTitle,
    String? selectedOptionId,
  })
  onVoteOffline;

  const CachedElectionsWidget({super.key, required this.onVoteOffline});

  @override
  State<CachedElectionsWidget> createState() => _CachedElectionsWidgetState();
}

class _CachedElectionsWidgetState extends State<CachedElectionsWidget> {
  final OfflineSyncService _offlineSync = OfflineSyncService.instance;
  List<Map<String, dynamic>> _cachedElections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedElections();
  }

  Future<void> _loadCachedElections() async {
    setState(() => _isLoading = true);

    // Mock cached elections - in production, load from Hive
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _cachedElections = [
        {
          'id': 'election_1',
          'title': 'Community Budget Allocation 2026',
          'description': 'Vote on how to allocate community funds',
          'options': [
            {'id': 'opt_1', 'title': 'Infrastructure'},
            {'id': 'opt_2', 'title': 'Education'},
            {'id': 'opt_3', 'title': 'Healthcare'},
          ],
          'cached_at': DateTime.now().subtract(const Duration(hours: 2)),
        },
        {
          'id': 'election_2',
          'title': 'New Park Location',
          'description': 'Choose the location for the new community park',
          'options': [
            {'id': 'opt_1', 'title': 'North District'},
            {'id': 'opt_2', 'title': 'South District'},
          ],
          'cached_at': DateTime.now().subtract(const Duration(hours: 5)),
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_download,
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 2.w),
              Text(
                'Cached Elections',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${_cachedElections.length} available',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_cachedElections.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Text(
                  'No cached elections available',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            ..._cachedElections.map((election) => _buildElectionCard(election)),
        ],
      ),
    );
  }

  Widget _buildElectionCard(Map<String, dynamic> election) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppTheme.primaryLight.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            election['title'],
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            election['description'],
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...List<Map<String, dynamic>>.from(
            election['options'],
          ).map((option) => _buildOptionButton(election, option)),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    Map<String, dynamic> election,
    Map<String, dynamic> option,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ElevatedButton(
        onPressed: () => widget.onVoteOffline(
          electionId: election['id'],
          electionTitle: election['title'],
          selectedOptionId: option['id'],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryLight,
          padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 3.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: AppTheme.primaryLight.withAlpha(51)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.how_to_vote, size: 5.w),
            SizedBox(width: 2.w),
            Text(option['title'], style: TextStyle(fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }
}
