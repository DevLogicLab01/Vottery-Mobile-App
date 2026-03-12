import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/// Service for fetching real-time currency exchange rates from external APIs
class CurrencyExchangeService {
  static CurrencyExchangeService? _instance;
  static CurrencyExchangeService get instance =>
      _instance ??= CurrencyExchangeService._();

  CurrencyExchangeService._();

  // Using exchangerate-api.com (free tier)
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';

  Map<String, double> _cachedRates = {};
  DateTime? _lastFetchTime;
  Timer? _autoRefreshTimer;

  /// Get exchange rates with auto-refresh every 5 minutes
  Future<Map<String, double>> getExchangeRates({
    String baseCurrency = 'USD',
    bool forceRefresh = false,
  }) async {
    try {
      // Check if cache is still valid (5 minutes)
      if (!forceRefresh &&
          _cachedRates.isNotEmpty &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
        return _cachedRates;
      }

      final response = await http
          .get(Uri.parse('$_baseUrl/$baseCurrency'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, double>.from(
          (data['rates'] as Map).map(
            (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
          ),
        );

        _cachedRates = rates;
        _lastFetchTime = DateTime.now();

        return rates;
      } else {
        debugPrint('Exchange rate API error: ${response.statusCode}');
        return _cachedRates.isNotEmpty ? _cachedRates : _getDefaultRates();
      }
    } catch (e) {
      debugPrint('Get exchange rates error: $e');
      return _cachedRates.isNotEmpty ? _cachedRates : _getDefaultRates();
    }
  }

  /// Convert amount between currencies
  double convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required Map<String, double> rates,
  }) {
    if (fromCurrency == toCurrency) return amount;

    final fromRate = rates[fromCurrency] ?? 1.0;
    final toRate = rates[toCurrency] ?? 1.0;

    // Convert to USD first, then to target currency
    final usdAmount = amount / fromRate;
    return usdAmount * toRate;
  }

  /// Start auto-refresh timer (every 5 minutes)
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => getExchangeRates(forceRefresh: true),
    );
  }

  /// Stop auto-refresh timer
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  /// Get default rates (fallback)
  Map<String, double> _getDefaultRates() {
    return {
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.79,
      'CNY': 7.24,
      'JPY': 149.50,
      'AUD': 1.53,
      'CAD': 1.36,
      'CHF': 0.88,
      'INR': 83.12,
      'MXN': 17.05,
      'BRL': 4.97,
      'ZAR': 18.65,
      'AED': 3.67,
      'SGD': 1.34,
      'HKD': 7.83,
    };
  }

  /// Get currency symbol
  String getCurrencySymbol(String currencyCode) {
    const symbols = {
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'CNY': '¥',
      'JPY': '¥',
      'AUD': r'A$',
      'CAD': r'C$',
      'CHF': 'CHF',
      'INR': '₹',
      'MXN': r'$',
      'BRL': r'R$',
      'ZAR': 'R',
      'AED': 'د.إ',
      'SGD': r'S$',
      'HKD': r'HK$',
    };
    return symbols[currencyCode] ?? currencyCode;
  }

  void dispose() {
    stopAutoRefresh();
  }
}
