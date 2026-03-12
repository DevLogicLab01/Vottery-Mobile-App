import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/telnyx_sms_service.dart';
import '../../../services/supabase_service.dart';

class ProviderHealthCardsWidget extends StatefulWidget {
  final String currentProvider;

  const ProviderHealthCardsWidget({super.key, required this.currentProvider});

  @override
  State<ProviderHealthCardsWidget> createState() =>
      _ProviderHealthCardsWidgetState();
}

class _ProviderHealthCardsWidgetState extends State<ProviderHealthCardsWidget> {
  final _telnyxService = TelnyxSMSService.instance;
  final _supabase = SupabaseService.instance.client;

  Map<String, dynamic> _telnyxHealth = {};
  Map<String, dynamic> _twilioHealth = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    setState(() => _isLoading = true);

    try {
      // Get latest health metrics
      final telnyxMetrics = await _supabase
          .from('provider_health_metrics')
          .select()
          .eq('provider_name', 'telnyx')
          .order('checked_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final twilioMetrics = await _supabase
          .from('provider_health_metrics')
          .select()
          .eq('provider_name', 'twilio')
          .order('checked_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _telnyxHealth = telnyxMetrics ?? {};
          _twilioHealth = twilioMetrics ?? {};
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provider Health',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildHealthCard(
                'Telnyx',
                _telnyxHealth,
                Colors.blue,
                widget.currentProvider == 'telnyx',
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildHealthCard(
                'Twilio',
                _twilioHealth,
                Colors.orange,
                widget.currentProvider == 'twilio',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthCard(
    String name,
    Map<String, dynamic> health,
    Color color,
    bool isActive,
  ) {
    final isHealthy = health['is_healthy'] == true;
    final latency = health['latency_ms'] ?? 0;
    final errorRate = health['error_rate'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 6,
                backgroundColor: isHealthy ? Colors.green : Colors.red,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildMetricRow('Latency', '${latency}ms', _getLatencyColor(latency)),
          SizedBox(height: 1.h),
          _buildMetricRow(
            'Error Rate',
            '${errorRate.toStringAsFixed(1)}%',
            errorRate < 5 ? Colors.green : Colors.red,
          ),
          SizedBox(height: 1.h),
          Text(
            isHealthy ? 'HEALTHY' : 'DEGRADED',
            style: TextStyle(
              fontSize: 10.sp,
              color: isHealthy ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getLatencyColor(int latency) {
    if (latency < 1000) return Colors.green;
    if (latency < 3000) return Colors.orange;
    return Colors.red;
  }
}
