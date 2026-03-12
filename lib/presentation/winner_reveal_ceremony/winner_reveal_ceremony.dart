import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Winner Reveal Ceremony - Immersive gamified experience for announcing
/// election winners with sequential reveal animations and celebration effects
class WinnerRevealCeremony extends StatefulWidget {
  final String electionId;

  const WinnerRevealCeremony({super.key, required this.electionId});

  @override
  State<WinnerRevealCeremony> createState() => _WinnerRevealCeremonyState();
}

class _WinnerRevealCeremonyState extends State<WinnerRevealCeremony>
    with TickerProviderStateMixin {
  final AuthService _auth = AuthService.instance;

  bool _isLoading = true;
  bool _isRevealing = false;
  bool _showConfetti = false;
  int _currentWinnerIndex = 0;
  List<Map<String, dynamic>> _winners = [];
  Map<String, dynamic>? _election;
  late AnimationController _spinController;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _loadWinnersData();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadWinnersData() async {
    setState(() => _isLoading = true);

    try {
      // Load election details
      final electionResponse = await SupabaseService.instance.client
          .from('elections')
          .select()
          .eq('id', widget.electionId)
          .single();

      setState(() => _election = electionResponse);

      // Load winners
      final winnersResponse = await SupabaseService.instance.client
          .from('election_winners')
          .select('*, user_profiles(username, avatar_url)')
          .eq('election_id', widget.electionId)
          .order('winner_position', ascending: true);

      setState(() {
        _winners = List<Map<String, dynamic>>.from(winnersResponse);
        _isLoading = false;
      });

      // Auto-start ceremony if winners exist and not revealed
      if (_winners.isNotEmpty && _winners.first['revealed_at'] == null) {
        await Future.delayed(const Duration(seconds: 2));
        _startRevealSequence();
      }
    } catch (e) {
      debugPrint('Load winners data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startRevealSequence() async {
    setState(() => _isRevealing = true);

    for (int i = 0; i < _winners.length; i++) {
      setState(() => _currentWinnerIndex = i);

      // Spin animation
      await _spinController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      _spinController.reset();

      // Show confetti
      setState(() => _showConfetti = true);
      _confettiController.forward();

      // Update revealed_at in database
      await SupabaseService.instance.client
          .from('election_winners')
          .update({'revealed_at': DateTime.now().toIso8601String()})
          .eq('id', _winners[i]['id']);

      // Wait 3 seconds before next winner
      if (i < _winners.length - 1) {
        await Future.delayed(const Duration(seconds: 3));
        setState(() => _showConfetti = false);
        _confettiController.reset();
      }
    }

    setState(() => _isRevealing = false);
  }

  void _skipToSummary() {
    setState(() {
      _isRevealing = false;
      _currentWinnerIndex = _winners.length;
    });
  }

  String _getPositionBadge(int position) {
    switch (position) {
      case 1:
        return '🥇 1st Place';
      case 2:
        return '🥈 2nd Place';
      case 3:
        return '🥉 3rd Place';
      default:
        return '🏆 ${position}th Place';
    }
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.accentLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'WinnerRevealCeremony',
      onRetry: _loadWinnersData,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isRevealing ? null : CustomAppBar(title: 'Winner Reveal'),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.vibrantYellow),
              )
            : Stack(
                children: [
                  // Main Content
                  if (_isRevealing && _currentWinnerIndex < _winners.length)
                    _buildRevealingView()
                  else
                    _buildSummaryView(),

                  // Confetti Overlay
                  if (_showConfetti)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Lottie.asset(
                          'assets/animations/confetti.json',
                          controller: _confettiController,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // Skip Button
                  if (_isRevealing)
                    Positioned(
                      top: 4.h,
                      right: 4.w,
                      child: TextButton(
                        onPressed: _skipToSummary,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildRevealingView() {
    final winner = _winners[_currentWinnerIndex];
    final userProfile = winner['user_profiles'] as Map<String, dynamic>?;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'WINNER REVEAL',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.vibrantYellow,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 4.h),

          // Slot Machine Reels
          Container(
            height: 20.h,
            width: 80.w,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.vibrantYellow, width: 2),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _spinController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _spinController.value * 6.28,
                    child: Icon(
                      Icons.emoji_events,
                      size: 60.sp,
                      color: AppTheme.vibrantYellow,
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(height: 4.h),

          // Winner Card
          if (!_spinController.isAnimating)
            Container(
              width: 80.w,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getPositionColor(winner['winner_position']),
                    _getPositionColor(winner['winner_position']).withAlpha(153),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _getPositionBadge(winner['winner_position']),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: userProfile?['avatar_url'] != null
                        ? NetworkImage(userProfile!['avatar_url'])
                        : null,
                    child: userProfile?['avatar_url'] == null
                        ? Icon(Icons.person, size: 40)
                        : null,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    userProfile?['username'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Prize: \$${(winner['prize_amount'] ?? 0.0).toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.white),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).scale(),

          SizedBox(height: 4.h),

          // Progress Indicator
          Text(
            'Winner ${_currentWinnerIndex + 1} of ${_winners.length}',
            style: TextStyle(fontSize: 12.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Text(
            'All Winners',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.vibrantYellow,
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView.builder(
              itemCount: _winners.length,
              itemBuilder: (context, index) {
                final winner = _winners[index];
                final userProfile =
                    winner['user_profiles'] as Map<String, dynamic>?;
                return Card(
                  color: Colors.grey[900],
                  margin: EdgeInsets.symmetric(vertical: 1.h),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userProfile?['avatar_url'] != null
                          ? NetworkImage(userProfile!['avatar_url'])
                          : null,
                      child: userProfile?['avatar_url'] == null
                          ? Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      userProfile?['username'] ?? 'Unknown',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _getPositionBadge(winner['winner_position']),
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: Text(
                      '\$${(winner['prize_amount'] ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: _getPositionColor(winner['winner_position']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _shareWinners,
                  child: Text('Share'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareWinners() async {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }
}
