import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FilterState extends ChangeNotifier {
  Map<String, dynamic> _activeFilters = {};
  DateTime? _appliedDate;
  final List<Map<String, dynamic>> _filterHistory = [];

  Map<String, dynamic> get activeFilters => _activeFilters;
  DateTime? get appliedDate => _appliedDate;
  List<Map<String, dynamic>> get filterHistory => _filterHistory;

  bool get hasActiveFilters => _activeFilters.isNotEmpty;

  /// Apply filter to dashboard
  void applyFilter(String filterType, dynamic value) {
    _activeFilters[filterType] = value;
    _appliedDate = DateTime.now();
    _addToHistory(filterType, value);
    _saveFiltersToPreferences();
    notifyListeners();
  }

  /// Remove specific filter
  void removeFilter(String filterType) {
    _activeFilters.remove(filterType);
    if (_activeFilters.isEmpty) {
      _appliedDate = null;
    }
    _saveFiltersToPreferences();
    notifyListeners();
  }

  /// Clear all filters
  void clearAllFilters() {
    _activeFilters.clear();
    _appliedDate = null;
    _saveFiltersToPreferences();
    notifyListeners();
  }

  /// Add filter to history stack
  void _addToHistory(String filterType, dynamic value) {
    _filterHistory.add({
      'filter_type': filterType,
      'value': value,
      'applied_at': DateTime.now().toIso8601String(),
    });

    // Keep only last 10 filters
    if (_filterHistory.length > 10) {
      _filterHistory.removeAt(0);
    }
  }

  /// Undo last filter
  void undoLastFilter() {
    if (_filterHistory.isNotEmpty) {
      final lastFilter = _filterHistory.removeLast();
      _activeFilters.remove(lastFilter['filter_type']);
      _saveFiltersToPreferences();
      notifyListeners();
    }
  }

  /// Save filters to SharedPreferences
  Future<void> _saveFiltersToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_dashboard_filters',
        jsonEncode(_activeFilters),
      );
    } catch (e) {
      debugPrint('Save filters error: $e');
    }
  }

  /// Load filters from SharedPreferences
  Future<void> loadFiltersFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filtersJson = prefs.getString('user_dashboard_filters');

      if (filtersJson != null) {
        _activeFilters = Map<String, dynamic>.from(jsonDecode(filtersJson));
        if (_activeFilters.isNotEmpty) {
          _appliedDate = DateTime.now();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load filters error: $e');
    }
  }

  /// Clear filters on logout
  Future<void> clearFiltersOnLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_dashboard_filters');
      _activeFilters.clear();
      _appliedDate = null;
      _filterHistory.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Clear filters on logout error: $e');
    }
  }

  /// Get filter value by type
  dynamic getFilterValue(String filterType) {
    return _activeFilters[filterType];
  }

  /// Check if specific filter is active
  bool isFilterActive(String filterType) {
    return _activeFilters.containsKey(filterType);
  }
}

class GlobalFilterProvider extends ChangeNotifier {
  static GlobalFilterProvider? _instance;
  static GlobalFilterProvider get instance =>
      _instance ??= GlobalFilterProvider._();

  GlobalFilterProvider._();

  final FilterState _filterState = FilterState();

  FilterState get filterState => _filterState;

  /// Initialize provider
  Future<void> initialize() async {
    await _filterState.loadFiltersFromPreferences();
  }

  /// Apply filter and broadcast to all listeners
  void applyFilter(String filterType, dynamic value) {
    _filterState.applyFilter(filterType, value);
    notifyListeners();
  }

  /// Remove filter
  void removeFilter(String filterType) {
    _filterState.removeFilter(filterType);
    notifyListeners();
  }

  /// Clear all filters
  void clearAllFilters() {
    _filterState.clearAllFilters();
    notifyListeners();
  }

  /// Undo last filter
  void undoLastFilter() {
    _filterState.undoLastFilter();
    notifyListeners();
  }
}
