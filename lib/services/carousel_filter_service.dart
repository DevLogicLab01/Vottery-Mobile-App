import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// Filter State Model
class FilterState {
  final Set<String> selectedCategories;
  final bool isTrendingOnly;
  final RangeValues? priceRange;
  final double? minRating;
  final DateTimeRange? dateRange;
  final String sortBy;
  final Set<String> contentTypes;

  FilterState({
    this.selectedCategories = const {},
    this.isTrendingOnly = false,
    this.priceRange,
    this.minRating,
    this.dateRange,
    this.sortBy = 'most_recent',
    this.contentTypes = const {},
  });

  FilterState copyWith({
    Set<String>? selectedCategories,
    bool? isTrendingOnly,
    RangeValues? priceRange,
    double? minRating,
    DateTimeRange? dateRange,
    String? sortBy,
    Set<String>? contentTypes,
  }) {
    return FilterState(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      isTrendingOnly: isTrendingOnly ?? this.isTrendingOnly,
      priceRange: priceRange ?? this.priceRange,
      minRating: minRating ?? this.minRating,
      dateRange: dateRange ?? this.dateRange,
      sortBy: sortBy ?? this.sortBy,
      contentTypes: contentTypes ?? this.contentTypes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedCategories': selectedCategories.toList(),
      'isTrendingOnly': isTrendingOnly,
      'priceRange': priceRange != null
          ? {'start': priceRange!.start, 'end': priceRange!.end}
          : null,
      'minRating': minRating,
      'dateRange': dateRange != null
          ? {
              'start': dateRange!.start.toIso8601String(),
              'end': dateRange!.end.toIso8601String(),
            }
          : null,
      'sortBy': sortBy,
      'contentTypes': contentTypes.toList(),
    };
  }

  factory FilterState.fromJson(Map<String, dynamic> json) {
    return FilterState(
      selectedCategories: Set<String>.from(
        json['selectedCategories'] as List? ?? [],
      ),
      isTrendingOnly: json['isTrendingOnly'] as bool? ?? false,
      priceRange: json['priceRange'] != null
          ? RangeValues(
              (json['priceRange']['start'] as num).toDouble(),
              (json['priceRange']['end'] as num).toDouble(),
            )
          : null,
      minRating: json['minRating'] as double?,
      dateRange: json['dateRange'] != null
          ? DateTimeRange(
              start: DateTime.parse(json['dateRange']['start'] as String),
              end: DateTime.parse(json['dateRange']['end'] as String),
            )
          : null,
      sortBy: json['sortBy'] as String? ?? 'most_recent',
      contentTypes: Set<String>.from(json['contentTypes'] as List? ?? []),
    );
  }
}

class RangeValues {
  final double start;
  final double end;

  RangeValues(this.start, this.end);
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}

/// Carousel Filter Service
class CarouselFilterService {
  static CarouselFilterService? _instance;
  static CarouselFilterService get instance =>
      _instance ??= CarouselFilterService._();

  CarouselFilterService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Save filter state to local storage
  Future<void> saveFilterState({
    required String contentType,
    required FilterState filterState,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_filters_$contentType';
      final json = filterState.toJson();
      await prefs.setString(key, jsonEncode(json));
    } catch (e) {
      debugPrint('Save filter state error: $e');
    }
  }

  /// Load filter state from local storage
  Future<FilterState?> loadFilterState({required String contentType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_filters_$contentType';
      final jsonString = prefs.getString(key);

      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return FilterState.fromJson(json);
    } catch (e) {
      debugPrint('Load filter state error: $e');
      return null;
    }
  }

  /// Save filter preset
  Future<bool> saveFilterPreset({
    required String presetName,
    required String contentType,
    required FilterState filterState,
    bool isDefault = false,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('user_filter_presets').insert({
        'user_id': _auth.currentUser!.id,
        'preset_name': presetName,
        'content_type': contentType,
        'filter_config': filterState.toJson(),
        'is_default': isDefault,
      });

      return true;
    } catch (e) {
      debugPrint('Save filter preset error: $e');
      return false;
    }
  }

  /// Get user filter presets
  Future<List<Map<String, dynamic>>> getFilterPresets({
    required String contentType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('user_filter_presets')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('content_type', contentType)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get filter presets error: $e');
      return [];
    }
  }

  /// Delete filter preset
  Future<bool> deleteFilterPreset({required String presetId}) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('user_filter_presets')
          .delete()
          .eq('preset_id', presetId)
          .eq('user_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Delete filter preset error: $e');
      return false;
    }
  }

  /// Track filter usage analytics
  Future<void> trackFilterUsage({
    required String contentType,
    required FilterState filterState,
    required int resultsCount,
    int? engagementTimeSeconds,
    String? actionTaken,
  }) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.from('filter_analytics').insert({
        'user_id': _auth.currentUser!.id,
        'content_type': contentType,
        'filter_applied': filterState.toJson(),
        'results_count': resultsCount,
        'engagement_time_seconds': engagementTimeSeconds,
        'action_taken': actionTaken,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Track filter usage error: $e');
    }
  }

  /// Get filter analytics
  Future<Map<String, dynamic>> getFilterAnalytics({
    required String contentType,
  }) async {
    try {
      final response = await _client
          .from('filter_analytics')
          .select()
          .eq('content_type', contentType)
          .gte(
            'recorded_at',
            DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          );

      final analytics = List<Map<String, dynamic>>.from(response);

      if (analytics.isEmpty) {
        return {
          'most_used_filters': [],
          'avg_results_count': 0,
          'conversion_rate': 0.0,
        };
      }

      // Calculate most used filters
      final filterCounts = <String, int>{};
      for (final record in analytics) {
        final filterApplied = record['filter_applied'] as Map<String, dynamic>;
        final categories = filterApplied['selectedCategories'] as List? ?? [];
        for (final category in categories) {
          filterCounts[category as String] = (filterCounts[category] ?? 0) + 1;
        }
      }

      final mostUsedFilters =
          filterCounts.entries
              .map((e) => {'filter': e.key, 'count': e.value})
              .toList()
            ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // Calculate average results
      final avgResults =
          analytics
              .map((a) => a['results_count'] as int? ?? 0)
              .fold<int>(0, (sum, count) => sum + count) /
          analytics.length;

      // Calculate conversion rate
      final conversions = analytics
          .where((a) => a['action_taken'] != null)
          .length;
      final conversionRate = (conversions / analytics.length) * 100;

      return {
        'most_used_filters': mostUsedFilters.take(5).toList(),
        'avg_results_count': avgResults,
        'conversion_rate': conversionRate,
      };
    } catch (e) {
      debugPrint('Get filter analytics error: $e');
      return {
        'most_used_filters': [],
        'avg_results_count': 0,
        'conversion_rate': 0.0,
      };
    }
  }

  /// Get smart filter suggestions based on user behavior
  Future<List<String>> getSmartFilterSuggestions({
    required String contentType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('filter_analytics')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('content_type', contentType)
          .gte(
            'recorded_at',
            DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
          )
          .order('recorded_at', ascending: false)
          .limit(20);

      final analytics = List<Map<String, dynamic>>.from(response);

      if (analytics.isEmpty) return [];

      // Analyze most used categories
      final categoryCounts = <String, int>{};
      for (final record in analytics) {
        final filterApplied = record['filter_applied'] as Map<String, dynamic>;
        final categories = filterApplied['selectedCategories'] as List? ?? [];
        for (final category in categories) {
          categoryCounts[category as String] =
              (categoryCounts[category] ?? 0) + 1;
        }
      }

      // Return top 3 suggestions
      final suggestions = categoryCounts.entries.map((e) => e.key).toList()
        ..sort(
          (a, b) => (categoryCounts[b] ?? 0).compareTo(categoryCounts[a] ?? 0),
        );

      return suggestions.take(3).toList();
    } catch (e) {
      debugPrint('Get smart filter suggestions error: $e');
      return [];
    }
  }

  /// Apply filters to query
  dynamic applyFilters({
    required PostgrestFilterBuilder query,
    required FilterState filterState,
  }) {
    // Apply category filter
    if (filterState.selectedCategories.isNotEmpty &&
        !filterState.selectedCategories.contains('all')) {
      query = query.inFilter(
        'category',
        filterState.selectedCategories.toList(),
      );
    }

    // Apply trending filter
    if (filterState.isTrendingOnly) {
      query = query.gt('trending_score', 80);
    }

    // Apply price range filter
    if (filterState.priceRange != null) {
      query = query
          .gte('price', filterState.priceRange!.start)
          .lte('price', filterState.priceRange!.end);
    }

    // Apply rating filter
    if (filterState.minRating != null) {
      query = query.gte('rating', filterState.minRating!);
    }

    // Apply date range filter
    if (filterState.dateRange != null) {
      query = query
          .gte('created_at', filterState.dateRange!.start.toIso8601String())
          .lte('created_at', filterState.dateRange!.end.toIso8601String());
    }

    // Apply sort
    switch (filterState.sortBy) {
      case 'most_recent':
        return query.order('created_at', ascending: false);
      case 'most_popular':
        return query.order('trending_score', ascending: false);
      case 'highest_rated':
        return query.order('rating', ascending: false);
      case 'price_low_high':
        return query.order('price', ascending: true);
      case 'price_high_low':
        return query.order('price', ascending: false);
    }

    return query;
  }
}
