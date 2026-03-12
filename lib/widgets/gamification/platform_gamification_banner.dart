import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformGamificationBanner extends StatefulWidget {
  const PlatformGamificationBanner({super.key});

  @override
  State<PlatformGamificationBanner> createState() =>
      _PlatformGamificationBannerState();
}

class _PlatformGamificationBannerState
    extends State<PlatformGamificationBanner> {
  Map<String, dynamic>? _campaign;
  bool _isLoading = true;
  Timer? _countdownTimer;
  Duration _timeUntilDraw = Duration.zero;
  final _client = SupabaseService.instance.client;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchCampaign();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchCampaign() async {
    try {
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final response = await _client
          .from('platform_gamification_campaigns')
          .select()
          .eq('month', monthKey)
          .eq('is_enabled', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _campaign = response;
          _isLoading = false;
        });
        if (_campaign != null) {
          _startCountdown();
        }
      }
    } catch (e) {
      debugPrint('PlatformGamificationBanner fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToChanges() {
    try {
      _channel = _client
          .channel('platform_gamification')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'platform_gamification_campaigns',
            callback: (_) => _fetchCampaign(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('PlatformGamificationBanner subscribe error: $e');
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (_campaign == null || !mounted) return;
    final drawDateStr = _campaign!['draw_date'] as String?;
    if (drawDateStr == null) return;
    final drawDate = DateTime.tryParse(drawDateStr);
    if (drawDate == null) return;
    final remaining = drawDate.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _timeUntilDraw = remaining.isNegative ? Duration.zero : remaining;
      });
    }
  }

  String _formatCountdown() {
    final days = _timeUntilDraw.inDays;
    final hours = _timeUntilDraw.inHours % 24;
    final minutes = _timeUntilDraw.inMinutes % 60;
    final seconds = _timeUntilDraw.inSeconds % 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m until draw';
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s until draw';
    return '${minutes}m ${seconds}s until draw';
  }

  void _showParticipationInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How to Participate'),
        content: const Text(
          'Stay active on the platform! Vote in elections, complete quests, '
          'and engage with the community to earn entries into the monthly draw. '
          'The more VP you earn, the higher your chances of winning!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (_campaign == null) return const SizedBox.shrink();

    final prizePool =
        (_campaign!['prize_pool_amount'] as num?)?.toDouble() ?? 0.0;
    final totalWinners = (_campaign!['total_winners'] as int?) ?? 1;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2FF7), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2FF7).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prize Pool Header
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 32,
                  color: Color(0xFFFFD700),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "This Month's Prize Pool",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${prizePool.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            // Winners Row
            Row(
              children: [
                const Icon(Icons.people, size: 20, color: Colors.white70),
                SizedBox(width: 2.w),
                Text(
                  '$totalWinners Winners This Month',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            // Countdown
            if (_timeUntilDraw > Duration.zero)
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.white70),
                  SizedBox(width: 2.w),
                  Text(
                    _formatCountdown(),
                    style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                  ),
                ],
              ),
            SizedBox(height: 1.5.h),
            // Participate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showParticipationInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7B2FF7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                ),
                child: Text(
                  'Stay Active to Enter',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}