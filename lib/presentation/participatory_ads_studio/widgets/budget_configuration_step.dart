import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class BudgetConfigurationStep extends StatefulWidget {
  final List<int> targetZones;
  final Map<int, Map<String, double>> budgetByZone;
  final ValueChanged<Map<int, Map<String, double>>> onBudgetChanged;

  const BudgetConfigurationStep({
    super.key,
    required this.targetZones,
    required this.budgetByZone,
    required this.onBudgetChanged,
  });

  @override
  State<BudgetConfigurationStep> createState() =>
      _BudgetConfigurationStepState();
}

class _BudgetConfigurationStepState extends State<BudgetConfigurationStep> {
  late Map<int, Map<String, double>> _budgetByZone;
  final Map<int, TextEditingController> _budgetControllers = {};
  final Map<int, TextEditingController> _cpeControllers = {};

  @override
  void initState() {
    super.initState();
    _budgetByZone = Map.from(widget.budgetByZone);
    for (final zone in widget.targetZones) {
      final existing = _budgetByZone[zone];
      _budgetControllers[zone] = TextEditingController(
        text: existing?['budget']?.toStringAsFixed(2) ?? '100.00',
      );
      _cpeControllers[zone] = TextEditingController(
        text: existing?['cpe']?.toStringAsFixed(2) ?? '0.50',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _budgetControllers.values) {
      c.dispose();
    }
    for (final c in _cpeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalBudget {
    return _budgetByZone.values.fold(
      0.0,
      (sum, zone) => sum + (zone['budget'] ?? 0.0),
    );
  }

  String _getZoneName(int zone) {
    const names = {
      1: 'US & Canada',
      2: 'Western Europe',
      3: 'Eastern Europe',
      4: 'Africa',
      5: 'Latin America',
      6: 'Middle East & Asia',
      7: 'Australasia',
      8: 'China & HK',
    };
    return names[zone] ?? 'Zone $zone';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Configuration',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Set budget and cost-per-engagement per zone',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          // Total budget card
          Container(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Budget',
                      style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                    ),
                    Text(
                      '\$${_totalBudget.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white70,
                  size: 24.sp,
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          if (widget.targetZones.isEmpty)
            Center(
              child: Text(
                'No zones selected. Go back to select target zones.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.targetZones.length,
              itemBuilder: (context, index) {
                final zone = widget.targetZones[index];
                return _buildZoneBudgetCard(zone);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildZoneBudgetCard(int zone) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  'Zone $zone',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                _getZoneName(zone),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _budgetControllers[zone],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Budget (\$)',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.2.h,
                    ),
                  ),
                  onChanged: (val) {
                    final budget = double.tryParse(val) ?? 0.0;
                    setState(() {
                      _budgetByZone[zone] = {
                        'budget': budget,
                        'cpe': _budgetByZone[zone]?['cpe'] ?? 0.50,
                      };
                    });
                    widget.onBudgetChanged(Map.from(_budgetByZone));
                  },
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: TextField(
                  controller: _cpeControllers[zone],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'CPE (\$)',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.2.h,
                    ),
                  ),
                  onChanged: (val) {
                    final cpe = double.tryParse(val) ?? 0.50;
                    setState(() {
                      _budgetByZone[zone] = {
                        'budget': _budgetByZone[zone]?['budget'] ?? 100.0,
                        'cpe': cpe,
                      };
                    });
                    widget.onBudgetChanged(Map.from(_budgetByZone));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
