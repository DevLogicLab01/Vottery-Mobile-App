import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Widget for selecting participation fee type and configuring pricing
class ParticipationFeeConfigWidget extends StatefulWidget {
  final String selectedFeeType;
  final double generalFeeAmount;
  final Map<String, double> regionalFeeAmounts;
  final Function(String) onFeeTypeChanged;
  final Function(double) onGeneralFeeChanged;
  final Function(Map<String, double>) onRegionalFeesChanged;

  const ParticipationFeeConfigWidget({
    super.key,
    required this.selectedFeeType,
    required this.generalFeeAmount,
    required this.regionalFeeAmounts,
    required this.onFeeTypeChanged,
    required this.onGeneralFeeChanged,
    required this.onRegionalFeesChanged,
  });

  @override
  State<ParticipationFeeConfigWidget> createState() =>
      _ParticipationFeeConfigWidgetState();
}

class _ParticipationFeeConfigWidgetState
    extends State<ParticipationFeeConfigWidget> {
  late Map<String, double> _regionalFees;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _generalFeeController = TextEditingController();

  final Map<String, String> _zoneNames = {
    'zone_1_us_canada': 'US & Canada',
    'zone_2_western_europe': 'Western Europe',
    'zone_3_eastern_europe': 'Eastern Europe',
    'zone_4_africa': 'Africa',
    'zone_5_latin_america': 'Latin America',
    'zone_6_middle_east_asia': 'Middle East & Asia',
    'zone_7_australasia': 'Australasia',
    'zone_8_china_hong_kong': 'China & Hong Kong',
  };

  @override
  void initState() {
    super.initState();
    _regionalFees = Map.from(widget.regionalFeeAmounts);
    _generalFeeController.text = widget.generalFeeAmount.toStringAsFixed(2);

    // Initialize controllers for regional fees
    _zoneNames.forEach((key, value) {
      _controllers[key] = TextEditingController(
        text: (_regionalFees[key] ?? 0.0).toStringAsFixed(2),
      );
    });
  }

  @override
  void dispose() {
    _generalFeeController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participation Fee',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildFeeTypeSelector(),
          SizedBox(height: 2.h),
          if (widget.selectedFeeType == 'paid_general') _buildGeneralFeeInput(),
          if (widget.selectedFeeType == 'paid_regional')
            _buildRegionalFeeInputs(),
        ],
      ),
    );
  }

  Widget _buildFeeTypeSelector() {
    return Column(
      children: [
        _buildFeeTypeOption(
          'free',
          'Free',
          'No participation fee. Election is completely free for all voters.',
          Icons.check_circle_outline,
        ),
        SizedBox(height: 1.h),
        _buildFeeTypeOption(
          'paid_general',
          'Paid (General Fee)',
          'Single participation fee for all participants worldwide.',
          Icons.attach_money,
        ),
        SizedBox(height: 1.h),
        _buildFeeTypeOption(
          'paid_regional',
          'Paid (Regional Fee)',
          'Different fees for 8 regional zones based on purchasing power.',
          Icons.public,
        ),
      ],
    );
  }

  Widget _buildFeeTypeOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = widget.selectedFeeType == value;

    return InkWell(
      onTap: () => widget.onFeeTypeChanged(value),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentLight.withAlpha(26) : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppTheme.accentLight : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentLight : Colors.grey,
              size: 8.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.accentLight
                          : AppTheme.primaryLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.accentLight, size: 6.w),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralFeeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Participation Fee Amount',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: _generalFeeController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Fee Amount (USD)',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            hintText: '0.00',
          ),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            widget.onGeneralFeeChanged(amount);
          },
        ),
      ],
    );
  }

  Widget _buildRegionalFeeInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Regional Fee Amounts',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Configure different participation fees for each regional zone based on purchasing power parity.',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
        ),
        SizedBox(height: 2.h),
        ..._zoneNames.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: 1.5.h),
            child: TextField(
              controller: _controllers[entry.key],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: entry.value,
                prefixIcon: Icon(Icons.location_on, size: 5.w),
                suffixText: 'USD',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                hintText: '0.00',
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                _regionalFees[entry.key] = amount;
                widget.onRegionalFeesChanged(_regionalFees);
              },
            ),
          );
        }),
      ],
    );
  }
}
