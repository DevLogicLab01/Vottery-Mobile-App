import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class FailoverMonitoringWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const FailoverMonitoringWidget({super.key, required this.onRefresh});

  @override
  State<FailoverMonitoringWidget> createState() =>
      _FailoverMonitoringWidgetState();
}

class _FailoverMonitoringWidgetState extends State<FailoverMonitoringWidget> {
  final _supabase = SupabaseService.instance.client;
  List<Map<String, dynamic>> _failoverHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFailoverHistory();
  }

  Future<void> _loadFailoverHistory() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('provider_failover_log')
          .select()
          .order('failed_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _failoverHistory = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_failoverHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'No failover events recorded',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: _failoverHistory.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final failover = _failoverHistory[index];
        return _buildFailoverCard(theme, failover);
      },
    );
  }

  Widget _buildFailoverCard(ThemeData theme, Map<String, dynamic> failover) {
    final fromProvider = failover['from_provider'] as String? ?? 'unknown';
    final toProvider = failover['to_provider'] as String? ?? 'unknown';
    final reason = failover['failover_reason'] as String? ?? 'Unknown reason';
    final triggeredBy = failover['triggered_by'] as String? ?? 'unknown';
    final failedAt = failover['failed_at'] as String?;
    final confidence = failover['confidence_score'] as num?;

    final isAutomatic = triggeredBy == 'automatic';

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAutomatic ? Colors.orange.withAlpha(51) : Colors.blue.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: isAutomatic
                      ? Colors.orange.withAlpha(26)
                      : Colors.blue.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAutomatic ? Icons.auto_fix_high : Icons.person,
                      size: 12.sp,
                      color: isAutomatic ? Colors.orange : Colors.blue,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      isAutomatic ? 'Automatic' : 'Manual',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: isAutomatic ? Colors.orange : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (confidence != null)
                Text(
                  '${(confidence * 100).toStringAsFixed(0)}% confidence',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProviderBadge(fromProvider, Colors.red),
              SizedBox(width: 2.w),
              Icon(Icons.arrow_forward, size: 20.sp, color: Colors.grey[600]),
              SizedBox(width: 2.w),
              _buildProviderBadge(toProvider, Colors.green),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            reason,
            style: TextStyle(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (failedAt != null) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.access_time, size: 12.sp, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  _formatTimestamp(failedAt),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderBadge(String provider, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Text(
        provider.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM d, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }
}