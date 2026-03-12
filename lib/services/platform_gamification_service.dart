import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class PlatformGamificationCampaign {
  final String id;
  final String month;
  final double prizePoolAmount;
  final int totalWinners;
  final DateTime drawDate;
  final bool isEnabled;
  final String? description;

  PlatformGamificationCampaign({
    required this.id,
    required this.month,
    required this.prizePoolAmount,
    required this.totalWinners,
    required this.drawDate,
    required this.isEnabled,
    this.description,
  });

  factory PlatformGamificationCampaign.fromMap(Map<String, dynamic> map) {
    return PlatformGamificationCampaign(
      id: map['id']?.toString() ?? '',
      month: map['month']?.toString() ?? '',
      prizePoolAmount: (map['prize_pool_amount'] as num?)?.toDouble() ?? 0.0,
      totalWinners: (map['total_winners'] as int?) ?? 0,
      drawDate: map['draw_date'] != null
          ? DateTime.parse(map['draw_date'].toString())
          : DateTime.now().add(const Duration(days: 30)),
      isEnabled: map['is_enabled'] as bool? ?? false,
      description: map['description']?.toString(),
    );
  }
}

class PlatformGamificationService {
  static final PlatformGamificationService instance =
      PlatformGamificationService._internal();
  PlatformGamificationService._internal();

  final _client = SupabaseService.instance.client;

  PlatformGamificationCampaign? _cachedCampaign;
  DateTime? _cacheExpiry;
  RealtimeChannel? _realtimeChannel;
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  Future<PlatformGamificationCampaign?> getCurrentMonthCampaign() async {
    // Return cached result if still valid (5 minutes)
    if (_cachedCampaign != null &&
        _cacheExpiry != null &&
        DateTime.now().isBefore(_cacheExpiry!)) {
      return _cachedCampaign;
    }

    try {
      final now = DateTime.now();
      final currentMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final response = await _client
          .from('platform_gamification_campaigns')
          .select()
          .eq('month', currentMonth)
          .eq('is_enabled', true)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        _cachedCampaign = null;
        _cacheExpiry = DateTime.now().add(const Duration(minutes: 5));
        return null;
      }

      final campaign = PlatformGamificationCampaign.fromMap(
        response.first,
      );
      _cachedCampaign = campaign;
      _cacheExpiry = DateTime.now().add(const Duration(minutes: 5));
      return campaign;
    } catch (e) {
      debugPrint('PlatformGamificationService error: $e');
      return null;
    }
  }

  void subscribeToRealtimeUpdates() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _client
        .channel('platform_gamification')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'platform_gamification_campaigns',
          callback: (payload) {
            // Invalidate cache on any change
            _cachedCampaign = null;
            _cacheExpiry = null;
            _notifyListeners();
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  void invalidateCache() {
    _cachedCampaign = null;
    _cacheExpiry = null;
  }
}
