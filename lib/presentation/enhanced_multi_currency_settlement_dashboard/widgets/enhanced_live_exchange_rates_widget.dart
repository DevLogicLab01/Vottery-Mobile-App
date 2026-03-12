import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/currency_exchange_service.dart';
import '../../../theme/app_theme.dart';

class EnhancedLiveExchangeRatesWidget extends StatelessWidget {
  final Map<String, double> exchangeRates;
  final VoidCallback onRefresh;

  const EnhancedLiveExchangeRatesWidget({
    super.key,
    required this.exchangeRates,
    required this.onRefresh,
  });

  static const List<String> mainCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'CNY',
    'JPY',
    'AUD',
    'CAD',
    'CHF',
    'INR',
    'MXN',
    'BRL',
    'ZAR',
    'AED',
    'SGD',
    'HKD',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyService = CurrencyExchangeService.instance;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildRefreshInfo(theme),
          SizedBox(height: 2.h),
          ...mainCurrencies.map((currency) {
            final rate = exchangeRates[currency] ?? 1.0;
            final symbol = currencyService.getCurrencySymbol(currency);
            return _buildRateCard(theme, currency, rate, symbol);
          }),
        ],
      ),
    );
  }

  Widget _buildRefreshInfo(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.accentLight, size: 5.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'Exchange rates auto-refresh every 5 minutes. Pull to refresh manually.',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard(
    ThemeData theme,
    String currency,
    double rate,
    String symbol,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Text(
                    symbol,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '1 USD = $symbol${rate.toStringAsFixed(4)}',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            rate.toStringAsFixed(4),
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
