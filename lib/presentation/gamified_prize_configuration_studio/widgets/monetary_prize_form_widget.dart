import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class MonetaryPrizeFormWidget extends StatefulWidget {
  final double amount;
  final String currency;
  final bool regionalPricingEnabled;
  final Map<String, double> regionalAmounts;
  final Function(Map<String, dynamic>) onDataChanged;

  const MonetaryPrizeFormWidget({
    super.key,
    required this.amount,
    required this.currency,
    required this.regionalPricingEnabled,
    required this.regionalAmounts,
    required this.onDataChanged,
  });

  @override
  State<MonetaryPrizeFormWidget> createState() =>
      _MonetaryPrizeFormWidgetState();
}

class _MonetaryPrizeFormWidgetState extends State<MonetaryPrizeFormWidget> {
  late TextEditingController _amountController;
  late String _selectedCurrency;
  late bool _regionalPricingEnabled;
  late Map<String, double> _regionalAmounts;

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD'];
  final Map<String, String> _zones = {
    'zone_1': 'Zone 1 (US/Canada)',
    'zone_2': 'Zone 2 (Western Europe)',
    'zone_3': 'Zone 3 (Eastern Europe)',
    'zone_4': 'Zone 4 (Africa)',
    'zone_5': 'Zone 5 (Latin America)',
    'zone_6': 'Zone 6 (Middle East/Asia)',
    'zone_7': 'Zone 7 (Australasia)',
    'zone_8': 'Zone 8 (China/Hong Kong)',
  };

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.amount > 0 ? widget.amount.toStringAsFixed(2) : '',
    );
    _selectedCurrency = widget.currency;
    _regionalPricingEnabled = widget.regionalPricingEnabled;
    _regionalAmounts = Map.from(widget.regionalAmounts);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onDataChanged({
      'amount': double.tryParse(_amountController.text) ?? 0.0,
      'currency': _selectedCurrency,
      'regionalPricingEnabled': _regionalPricingEnabled,
      'regionalAmounts': _regionalAmounts,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monetary Prize Details',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),

          // Amount and Currency
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Prize Amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) => _notifyChange(),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _currencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCurrency = value!);
                    _notifyChange();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Regional Pricing Toggle
          SwitchListTile(
            title: Text(
              'Enable Regional Pricing',
              style: TextStyle(fontSize: 12.sp),
            ),
            subtitle: Text(
              'Set different amounts for different zones',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
            ),
            value: _regionalPricingEnabled,
            onChanged: (value) {
              setState(() => _regionalPricingEnabled = value);
              _notifyChange();
            },
            activeThumbColor: AppTheme.primaryColor,
          ),

          // Regional Pricing Fields
          if (_regionalPricingEnabled) ...[
            SizedBox(height: 1.h),
            Text(
              'Zone-Based Amounts',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            ..._zones.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: TextField(
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: entry.value,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixText: '$_selectedCurrency ',
                  ),
                  controller: TextEditingController(
                    text: _regionalAmounts[entry.key]?.toStringAsFixed(2) ?? '',
                  ),
                  onChanged: (value) {
                    _regionalAmounts[entry.key] = double.tryParse(value) ?? 0.0;
                    _notifyChange();
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
