import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/offline_content_cache_service.dart';

class OfflineBannerWidget extends StatefulWidget {
  final Widget child;

  const OfflineBannerWidget({super.key, required this.child});

  @override
  State<OfflineBannerWidget> createState() => _OfflineBannerWidgetState();
}

class _OfflineBannerWidgetState extends State<OfflineBannerWidget> {
  final _cacheService = OfflineContentCacheService.instance;
  bool _isOnline = true;
  int _syncedItems = 0;
  bool _showSyncSuccess = false;
  StreamSubscription? _connectivitySub;
  StreamSubscription? _syncSub;

  @override
  void initState() {
    super.initState();
    _isOnline = _cacheService.isOnline;
    _connectivitySub = _cacheService.connectivityStream.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
    _syncSub = _cacheService.syncProgressStream.listen((event) {
      if (mounted) {
        setState(() {
          _syncedItems = event.processed;
          _showSyncSuccess = event.processed == event.total && event.total > 0;
        });
        if (_showSyncSuccess) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showSyncSuccess = false);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isOnline)
          Material(
            color: Colors.orange[700],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      "You're offline. Some features limited.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _cacheService.processSyncQueue(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_showSyncSuccess)
          Material(
            color: Colors.green[600],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 2.w),
                  Text(
                    'Back online! Synced $_syncedItems items.',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
