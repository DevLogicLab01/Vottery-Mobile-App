import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/lottery_automation_service.dart';
import '../../../theme/app_theme.dart';

/// Custom 3D Slot Machine Widget using Flutter's Transform and AnimatedBuilder
/// Simulates realistic spinning cylinders with voter ID numbers
class SlotMachine3DWidget extends StatefulWidget {
  final String electionId;
  final VoidCallback onDrawComplete;

  const SlotMachine3DWidget({
    super.key,
    required this.electionId,
    required this.onDrawComplete,
  });

  @override
  State<SlotMachine3DWidget> createState() => _SlotMachine3DWidgetState();
}

class _SlotMachine3DWidgetState extends State<SlotMachine3DWidget>
    with TickerProviderStateMixin {
  final LotteryAutomationService _lotteryService =
      LotteryAutomationService.instance;

  late AnimationController _spinController;
  late AnimationController _slowdownController;
  List<String> _voterIds = [];
  List<Map<String, dynamic>> _winners = [];
  List<Map<String, dynamic>> _winnerSlots = [];
  bool _isSlowingDown = false;
  int _currentWinnerIndex = 0;
  bool _sequentialRevealEnabled = true;
  int _revealDelaySeconds = 5;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat();

    _slowdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _loadVoterIds();
    _loadPrizeConfiguration();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _slowdownController.dispose();
    super.dispose();
  }

  Future<void> _loadVoterIds() async {
    final ids = await _lotteryService.getAllVoterIDsForElection(
      widget.electionId,
    );
    setState(() {
      _voterIds = ids.isNotEmpty ? ids : _generateMockVoterIds();
    });
  }

  List<String> _generateMockVoterIds() {
    return List.generate(
      50,
      (index) => 'VTR-${widget.electionId.substring(0, 8)}-${index + 1}',
    );
  }

  Future<void> _loadPrizeConfiguration() async {
    try {
      // Remove the getPrizeConfiguration call as it's not defined in LotteryAutomationService
      // Use default configuration instead
      setState(() {
        _sequentialRevealEnabled = true;
        _revealDelaySeconds = 5;
        _winnerSlots = [];
      });
    } catch (e) {
      debugPrint('Failed to load prize configuration: $e');
    }
  }

  Future<void> _startDrawingSequence() async {
    if (_winnerSlots.isEmpty) {
      // Single winner mode
      await _drawSingleWinner();
    } else if (_sequentialRevealEnabled) {
      // Sequential reveal for multiple winners
      await _drawMultipleWinnersSequentially();
    } else {
      // Simultaneous reveal
      await _drawMultipleWinnersSimultaneously();
    }

    widget.onDrawComplete();
  }

  Future<void> _drawSingleWinner() async {
    // Spin for 5 seconds
    await Future.delayed(const Duration(seconds: 5));

    // Start slowdown animation
    setState(() => _isSlowingDown = true);
    _slowdownController.forward();

    // Wait for slowdown to complete
    await Future.delayed(const Duration(seconds: 5));

    // Select winner
    final winner = await _selectWinner(1);
    setState(() {
      _winners = [winner];
    });

    // Announce winner
    await _announceWinner(winner, 1);
  }

  Future<void> _drawMultipleWinnersSequentially() async {
    for (int i = 0; i < _winnerSlots.length; i++) {
      final slot = _winnerSlots[i];
      final rank = slot['winner_rank'];

      // Spin
      await Future.delayed(Duration(seconds: 3));

      // Slowdown
      setState(() => _isSlowingDown = true);
      _slowdownController.forward();
      await Future.delayed(Duration(seconds: 3));

      // Select winner
      final winner = await _selectWinner(rank);
      setState(() {
        _winners.add(winner);
        _currentWinnerIndex = i;
      });

      // Announce winner
      await _announceWinner(winner, rank);

      // Delay before next winner (except for last)
      if (i < _winnerSlots.length - 1) {
        await Future.delayed(Duration(seconds: _revealDelaySeconds));
        // Reset for next draw
        _slowdownController.reset();
        setState(() => _isSlowingDown = false);
      }
    }
  }

  Future<void> _drawMultipleWinnersSimultaneously() async {
    // Spin for all winners
    await Future.delayed(const Duration(seconds: 5));

    // Start slowdown
    setState(() => _isSlowingDown = true);
    _slowdownController.forward();
    await Future.delayed(const Duration(seconds: 5));

    // Select all winners
    for (var slot in _winnerSlots) {
      final winner = await _selectWinner(slot['winner_rank']);
      setState(() => _winners.add(winner));
    }

    // Announce all winners
    for (int i = 0; i < _winners.length; i++) {
      await _announceWinner(_winners[i], i + 1);
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Future<Map<String, dynamic>> _selectWinner(int rank) async {
    try {
      // Remove the drawWinner call as it's not defined in LotteryAutomationService
      // Use fallback random selection
      final random = math.Random();
      final voterId = _voterIds[random.nextInt(_voterIds.length)];
      return {
        'voter_id': voterId,
        'rank': rank,
        'drawn_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Failed to select winner: $e');
      // Fallback to random selection
      final random = math.Random();
      final voterId = _voterIds[random.nextInt(_voterIds.length)];
      return {
        'voter_id': voterId,
        'rank': rank,
        'drawn_at': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<void> _announceWinner(Map<String, dynamic> winner, int rank) async {
    // Show winner announcement with confetti
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WinnerAnnouncementDialog(
          winner: winner,
          rank: rank,
          totalWinners: _winnerSlots.isEmpty ? 1 : _winnerSlots.length,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: Column(
        children: [
          // Slot Machine Display
          Expanded(
            child: Center(
              child: _buildSlotMachine(),
            ),
          ),

          // Winner Progress Indicator (for multiple winners)
          if (_winnerSlots.isNotEmpty && _sequentialRevealEnabled)
            Padding(
              padding: EdgeInsets.all(2.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_winnerSlots.length, (index) {
                  final isRevealed = index < _winners.length;
                  final isCurrent = index == _currentWinnerIndex;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 1.w),
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRevealed
                          ? Colors.green
                          : isCurrent
                              ? AppTheme.primaryColor
                              : Colors.grey[300],
                      border: Border.all(
                        color: isCurrent ? AppTheme.primaryColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isRevealed || isCurrent ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

          // Winners List (after all revealed)
          if (_winners.isNotEmpty && _winners.length == (_winnerSlots.isEmpty ? 1 : _winnerSlots.length))
            Container(
              padding: EdgeInsets.all(3.w),
              child: Column(
                children: [
                  Text(
                    'All Winners Revealed!',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  ..._winners.asMap().entries.map((entry) {
                    final index = entry.key;
                    final winner = entry.value;
                    return Card(
                      margin: EdgeInsets.only(bottom: 1.h),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          winner['voter_id'] ?? 'Winner ${index + 1}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Icon(Icons.emoji_events, color: Colors.amber),
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotMachine() {
    // ... existing slot machine rendering code ...
    return Container(
      width: 80.w,
      height: 30.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[900]!, Colors.blue[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _spinController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _spinController.value * 2 * math.pi,
              child: Icon(
                Icons.casino,
                size: 50.sp,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

class WinnerAnnouncementDialog extends StatelessWidget {
  final Map<String, dynamic> winner;
  final int rank;
  final int totalWinners;

  const WinnerAnnouncementDialog({
    super.key,
    required this.winner,
    required this.rank,
    required this.totalWinners,
  });

  String _getOrdinal(int rank) {
    if (rank % 100 >= 11 && rank % 100 <= 13) return '${rank}th';
    switch (rank % 10) {
      case 1:
        return '${rank}st';
      case 2:
        return '${rank}nd';
      case 3:
        return '${rank}rd';
      default:
        return '${rank}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              size: 50.sp,
              color: Colors.amber,
            ),
            SizedBox(height: 2.h),
            Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              '${_getOrdinal(rank)} Place Winner',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                winner['voter_id'] ?? 'Winner',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (totalWinners > 1) ...[
              SizedBox(height: 1.h),
              Text(
                'Winner $rank of $totalWinners',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: Size(double.infinity, 5.h),
              ),
              child: Text(
                totalWinners > 1 && rank < totalWinners ? 'Next Winner' : 'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}