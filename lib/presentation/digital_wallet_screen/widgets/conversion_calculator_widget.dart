import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class ConversionCalculatorWidget extends StatefulWidget {
  final Map<String, double> exchangeRates;

  const ConversionCalculatorWidget({super.key, required this.exchangeRates});

  @override
  State<ConversionCalculatorWidget> createState() =>
      _ConversionCalculatorWidgetState();
}

class _ConversionCalculatorWidgetState
    extends State<ConversionCalculatorWidget> {
  final _vpController = TextEditingController();
  String _selectedCurrency = 'USD';
  double _convertedAmount = 0.0;

  @override
  void dispose() {
    _vpController.dispose();
    super.dispose();
  }

  void _calculateConversion() {
    final vpAmount = int.tryParse(_vpController.text) ?? 0;
    final usdValue = vpAmount * 0.005; // 1 VP = $0.005
    final rate = widget.exchangeRates[_selectedCurrency] ?? 1.0;
    setState(() {
      _convertedAmount = usdValue * rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversion Calculator',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _vpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'VP Amount',
                    hintText: '1000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixText: 'VP',
                  ),
                  onChanged: (_) => _calculateConversion(),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items:
                      ['USD', 'EUR', 'GBP', 'JPY', 'INR', 'BRL', 'NGN', 'ZAR']
                          .map(
                            (currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = value!;
                      _calculateConversion();
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppTheme.primaryLight, width: 2.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Converted Amount',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${_getCurrencySymbol(_selectedCurrency)}${_convertedAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Exchange rate: 1 VP = \$0.005 USD',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
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
      'INR': '₹',
      'BRL': r'R$',
      'NGN': '₦',
      'ZAR': 'R',
    };
    return symbols[currency] ?? currency;
  }
}
