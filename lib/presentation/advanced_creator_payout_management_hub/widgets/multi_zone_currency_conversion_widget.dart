import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/currency_exchange_service.dart';
import '../../../theme/app_theme.dart';

class MultiZoneCurrencyConversionWidget extends StatefulWidget {
  final Map<String, double> exchangeRates;
  final Map<String, dynamic> earningsSummary;
  final VoidCallback onRefresh;

  const MultiZoneCurrencyConversionWidget({
    super.key,
    required this.exchangeRates,
    required this.earningsSummary,
    required this.onRefresh,
  });

  @override
  State<MultiZoneCurrencyConversionWidget> createState() =>
      _MultiZoneCurrencyConversionWidgetState();
}

class _MultiZoneCurrencyConversionWidgetState
    extends State<MultiZoneCurrencyConversionWidget> {
  final CurrencyExchangeService _currencyService =
      CurrencyExchangeService.instance;

  // 8 Purchasing Power Zones with multipliers
  final List<Map<String, dynamic>> _zones = [
    {
      'name': 'Zone 1: US/Canada/Western Europe',
      'multiplier': 1.0,
      'currencies': ['USD', 'CAD', 'EUR', 'GBP'],
    },
    {
      'name': 'Zone 2: Eastern Europe',
      'multiplier': 0.7,
      'currencies': ['PLN', 'CZK', 'HUF'],
    },
    {
      'name': 'Zone 3: Latin America',
      'multiplier': 0.6,
      'currencies': ['MXN', 'BRL', 'ARS'],
    },
    {
      'name': 'Zone 4: Middle East',
      'multiplier': 0.8,
      'currencies': ['AED', 'SAR', 'EGP'],
    },
    {
      'name': 'Zone 5: East Asia',
      'multiplier': 0.9,
      'currencies': ['JPY', 'KRW', 'CNY'],
    },
    {
      'name': 'Zone 6: Southeast Asia',
      'multiplier': 0.5,
      'currencies': ['THB', 'VND', 'PHP'],
    },
    {
      'name': 'Zone 7: South Asia',
      'multiplier': 0.4,
      'currencies': ['INR', 'PKR', 'BDT'],
    },
    {
      'name': 'Zone 8: Africa',
      'multiplier': 0.3,
      'currencies': ['ZAR', 'NGN', 'KES'],
    },
  ];

  bool _isRefreshing = false;

  Future<void> _refreshRates() async {
    setState(() => _isRefreshing = true);
    await _currencyService.getExchangeRates(forceRefresh: true);
    widget.onRefresh();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final availableBalance =
        (widget.earningsSummary['available_balance'] ?? 0.0) as num;
    final usdAmount = availableBalance.toDouble();

    return RefreshIndicator(
      onRefresh: _refreshRates,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatesHeader(),
            SizedBox(height: 3.h),
            ..._zones.map((zone) => _buildZoneCard(zone, usdAmount)),
          ],
        ),
      ),
    );
  }

  Widget _buildRatesHeader() {
    final lastUpdated = DateTime.now();
    final timeFormat = DateFormat('h:mm a');

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.currency_exchange,
            color: AppTheme.primaryLight,
            size: 6.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Exchange Rates',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Updated: ${timeFormat.format(lastUpdated)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (_isRefreshing)
            SizedBox(
              width: 5.w,
              height: 5.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryLight,
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh, size: 6.w),
              onPressed: _refreshRates,
            ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone, double usdAmount) {
    final multiplier = zone['multiplier'] as double;
    final adjustedAmount = usdAmount * multiplier;
    final currencies = zone['currencies'] as List<String>;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.primaryLight.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '${(multiplier * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  zone['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Adjusted Payout: \$${adjustedAmount.toStringAsFixed(2)} USD',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentLight,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: currencies
                .map((currency) => _buildCurrencyChip(currency, adjustedAmount))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyChip(String currency, double usdAmount) {
    final rate = widget.exchangeRates[currency] ?? 1.0;
    final convertedAmount = usdAmount * rate;
    final currencyFormat = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currency,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            currencyFormat.format(convertedAmount),
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    const symbols = {
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'INR': '₹',
      'CAD': r'C$',
      'AUD': r'A$',
    };
    return symbols[currency] ?? currency;
  }
}
