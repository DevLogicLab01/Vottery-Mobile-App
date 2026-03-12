import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/currency_exchange_service.dart';
import '../../../theme/app_theme.dart';

class LiveCurrencyRatesWidget extends StatefulWidget {
  final Map<String, double> exchangeRates;
  final VoidCallback onRefresh;

  const LiveCurrencyRatesWidget({
    super.key,
    required this.exchangeRates,
    required this.onRefresh,
  });

  @override
  State<LiveCurrencyRatesWidget> createState() =>
      _LiveCurrencyRatesWidgetState();
}

class _LiveCurrencyRatesWidgetState extends State<LiveCurrencyRatesWidget> {
  final List<String> _mainCurrencies = ['EUR', 'GBP', 'CNY', 'JPY', 'AUD'];
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double _amount = 100.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Live Currency Rates',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, size: 5.w),
              onPressed: widget.onRefresh,
              color: AppTheme.vibrantYellow,
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ..._mainCurrencies.map(
                (currency) => _buildRateRow(
                  currency,
                  widget.exchangeRates[currency] ?? 1.0,
                  theme,
                ),
              ),
              Divider(height: 3.h),
              _buildConverter(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRateRow(String currency, double rate, ThemeData theme) {
    final currencyService = CurrencyExchangeService.instance;
    final symbol = currencyService.getCurrencySymbol(currency);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: AppTheme.vibrantYellow.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Text(
                    symbol,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.vibrantYellow,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                currency,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Text(
            rate.toStringAsFixed(4),
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConverter(ThemeData theme) {
    final currencyService = CurrencyExchangeService.instance;
    final converted = currencyService.convertCurrency(
      amount: _amount,
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
      rates: widget.exchangeRates,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency Converter',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.h,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _amount = double.tryParse(value) ?? 100.0);
                },
                controller: TextEditingController(text: _amount.toString()),
              ),
            ),
            SizedBox(width: 2.w),
            DropdownButton<String>(
              value: _fromCurrency,
              items: [
                'USD',
                ..._mainCurrencies,
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) {
                setState(() => _fromCurrency = value!);
              },
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Icon(
              Icons.arrow_downward,
              size: 5.w,
              color: AppTheme.vibrantYellow,
            ),
            SizedBox(width: 2.w),
            Text(
              '${converted.toStringAsFixed(2)} $_toCurrency',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.vibrantYellow,
              ),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _toCurrency,
              items: _mainCurrencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() => _toCurrency = value!);
              },
            ),
          ],
        ),
      ],
    );
  }
}
