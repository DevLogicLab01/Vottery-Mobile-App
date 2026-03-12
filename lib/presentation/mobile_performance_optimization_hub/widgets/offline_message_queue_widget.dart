import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/message_queue_service.dart';

class OfflineMessageQueueWidget extends StatefulWidget {
  const OfflineMessageQueueWidget({super.key});

  @override
  State<OfflineMessageQueueWidget> createState() =>
      _OfflineMessageQueueWidgetState();
}

class _OfflineMessageQueueWidgetState extends State<OfflineMessageQueueWidget> {
  final MessageQueueService _queueService = MessageQueueService.instance;
  int _pendingCount = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final count = await _queueService.getPendingCount();
    if (mounted) setState(() => _pendingCount = count);
  }

  Future<void> _processQueue() async {
    setState(() => _isProcessing = true);
    await _queueService.processOfflineQueue();
    await _loadPendingCount();
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = _queueService.isOnline;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.queue, color: const Color(0xFF8B5CF6), size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Offline Message Queue',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF10B981).withAlpha(26)
                      : const Color(0xFFEF4444).withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_pendingCount',
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: _pendingCount > 0
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'Messages Queued',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_pendingCount > 0 && isOnline)
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processQueue,
                  icon: _isProcessing
                      ? SizedBox(
                          width: 4.w,
                          height: 4.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.sync, size: 4.w),
                  label: Text(
                    _isProcessing ? 'Syncing...' : 'Sync Now',
                    style: GoogleFonts.inter(fontSize: 11.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          // Priority breakdown
          Row(
            children: [
              _PriorityBadge(label: 'Critical', color: const Color(0xFFEF4444)),
              SizedBox(width: 2.w),
              _PriorityBadge(label: 'High', color: const Color(0xFFF59E0B)),
              SizedBox(width: 2.w),
              _PriorityBadge(label: 'Normal', color: const Color(0xFF6B7280)),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            _pendingCount > 0
                ? 'Messages queued - will send when online. Critical messages processed first.'
                : 'All messages delivered. Queue is empty.',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
