import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/currency_exchange_service.dart';
import '../../../theme/app_theme.dart';

class MultiCurrencyWalletWidget extends StatefulWidget {
  final Map<String, double> balances;
  final Map<String, double> exchangeRates;

  const MultiCurrencyWalletWidget({
    super.key,
    required this.balances,
    required this.exchangeRates,
  });

  @override
  State<MultiCurrencyWalletWidget> createState() =>
      _MultiCurrencyWalletWidgetState();
}

class _MultiCurrencyWalletWidgetState extends State<MultiCurrencyWalletWidget> {
  String _displayCurrency = 'USD';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyService = CurrencyExchangeService.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Multi-Currency Wallet',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            DropdownButton<String>(
              value: _displayCurrency,
              items: widget.balances.keys
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() => _displayCurrency = value!);
              },
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.vibrantYellow,
                AppTheme.vibrantYellow.withAlpha(179),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: AppTheme.vibrantYellow.withAlpha(77),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Balance',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white.withAlpha(230),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                _getTotalBalanceInCurrency(),
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2.h),
              ...widget.balances.entries.map((entry) {
                final symbol = currencyService.getCurrencySymbol(entry.key);
                final convertedAmount = currencyService.convertCurrency(
                  amount: entry.value,
                  fromCurrency: entry.key,
                  toCurrency: _displayCurrency,
                  rates: widget.exchangeRates,
                );

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 0.5.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${entry.key} $symbol',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                      Text(
                        '$symbol${entry.value.toStringAsFixed(2)} ≈ ${currencyService.getCurrencySymbol(_displayCurrency)}${convertedAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _getTotalBalanceInCurrency() {
    final currencyService = CurrencyExchangeService.instance;
    double total = 0.0;

    for (var entry in widget.balances.entries) {
      total += currencyService.convertCurrency(
        amount: entry.value,
        fromCurrency: entry.key,
        toCurrency: _displayCurrency,
        rates: widget.exchangeRates,
      );
    }

    final symbol = currencyService.getCurrencySymbol(_displayCurrency);
    return '$symbol${total.toStringAsFixed(2)}';
  }
}
