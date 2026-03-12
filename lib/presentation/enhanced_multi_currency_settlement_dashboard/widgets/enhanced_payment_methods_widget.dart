import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/currency_exchange_service.dart';
import '../../../theme/app_theme.dart';

class EnhancedPaymentMethodsWidget extends StatefulWidget {
  final Map<String, double> walletBalances;
  final Map<String, double> exchangeRates;

  const EnhancedPaymentMethodsWidget({
    super.key,
    required this.walletBalances,
    required this.exchangeRates,
  });

  @override
  State<EnhancedPaymentMethodsWidget> createState() =>
      _EnhancedPaymentMethodsWidgetState();
}

class _EnhancedPaymentMethodsWidgetState
    extends State<EnhancedPaymentMethodsWidget> {
  String _selectedCurrency = 'USD';

  static const Map<String, Map<String, dynamic>> paymentMethods = {
    'bank_transfer': {
      'name': 'Bank Transfer',
      'timeline': '3-5 business days',
      'icon': Icons.account_balance,
      'fee': '0%',
    },
    'PayPal': {
      'name': 'PayPal',
      'timeline': 'Instant',
      'icon': Icons.payment,
      'fee': '2.9%',
    },
    'Stripe': {
      'name': 'Stripe',
      'timeline': '2-7 business days',
      'icon': Icons.credit_card,
      'fee': '2.5%',
    },
    'crypto': {
      'name': 'Cryptocurrency',
      'timeline': '1-24 hours',
      'icon': Icons.currency_bitcoin,
      'fee': 'Network fees apply',
    },
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildWalletBalances(theme),
        SizedBox(height: 3.h),
        Text(
          'Payment Methods',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        ...paymentMethods.entries.map((entry) {
          return _buildPaymentMethodCard(theme, entry.key, entry.value);
        }),
      ],
    );
  }

  Widget _buildWalletBalances(ThemeData theme) {
    final currencyService = CurrencyExchangeService.instance;
    final currencies = ['USD', 'EUR', 'GBP', 'CNY', 'JPY'];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multi-Currency Wallet',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          DropdownButton<String>(
            value: _selectedCurrency,
            dropdownColor: AppTheme.primaryLight,
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white),
            underline: Container(),
            items: currencies
                .map(
                  (currency) =>
                      DropdownMenuItem(value: currency, child: Text(currency)),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedCurrency = value!);
            },
          ),
          SizedBox(height: 1.h),
          Text(
            _getConvertedBalance(),
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getConvertedBalance() {
    final usdBalance = widget.walletBalances['USD'] ?? 0.0;
    final currencyService = CurrencyExchangeService.instance;

    if (_selectedCurrency == 'USD') {
      return '\$${usdBalance.toStringAsFixed(2)}';
    }

    final converted = currencyService.convertCurrency(
      amount: usdBalance,
      fromCurrency: 'USD',
      toCurrency: _selectedCurrency,
      rates: widget.exchangeRates,
    );

    final symbol = currencyService.getCurrencySymbol(_selectedCurrency);
    return '$symbol${converted.toStringAsFixed(2)}';
  }

  Widget _buildPaymentMethodCard(
    ThemeData theme,
    String methodKey,
    Map<String, dynamic> method,
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
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppTheme.accentLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              method['icon'] as IconData,
              color: AppTheme.accentLight,
              size: 6.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 3.w,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      method['timeline'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Fee: ${method['fee']}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
