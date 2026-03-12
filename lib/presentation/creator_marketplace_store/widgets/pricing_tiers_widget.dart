import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PricingTiersWidget extends StatefulWidget {
  final List<Map<String, dynamic>> tiers;
  final Function(Map<String, dynamic>) onSelectTier;

  const PricingTiersWidget({
    super.key,
    required this.tiers,
    required this.onSelectTier,
  });

  @override
  State<PricingTiersWidget> createState() => _PricingTiersWidgetState();
}

class _PricingTiersWidgetState extends State<PricingTiersWidget> {
  bool _showComparison = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pricing Tiers',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            TextButton(
              onPressed: () =>
                  setState(() => _showComparison = !_showComparison),
              child: Text(
                _showComparison ? 'Hide Comparison' : 'Compare Tiers',
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        if (_showComparison) _buildComparisonTable() else ..._buildTierCards(),
      ],
    );
  }

  List<Widget> _buildTierCards() {
    return widget.tiers.map((tier) {
      final name = tier['name'] as String;
      final price = tier['price'] as num;
      final deliverables = tier['deliverables'] as List;
      final isPopular = name == 'Standard';

      return Container(
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isPopular ? AppTheme.primaryLight : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: isPopular
                    ? AppTheme.primaryLight
                    : AppTheme.textSecondaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isPopular
                              ? Colors.white
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                      if (isPopular)
                        Text(
                          'Most Popular',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '\$${price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isPopular ? Colors.white : AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What\'s Included:',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  ...deliverables.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              item as String,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => widget.onSelectTier(tier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Select & Continue',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildComparisonTable() {
    final allDeliverables = <String>{};
    for (final tier in widget.tiers) {
      allDeliverables.addAll((tier['deliverables'] as List).cast<String>());
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'Feature',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
          ),
          ...widget.tiers.map(
            (tier) => DataColumn(
              label: Text(
                tier['name'] as String,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        rows: [
          DataRow(
            cells: [
              DataCell(Text('Price', style: TextStyle(fontSize: 11.sp))),
              ...widget.tiers.map(
                (tier) => DataCell(
                  Text(
                    '\$${(tier['price'] as num).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ...allDeliverables.map((deliverable) {
            return DataRow(
              cells: [
                DataCell(Text(deliverable, style: TextStyle(fontSize: 11.sp))),
                ...widget.tiers.map((tier) {
                  final hasFeature = (tier['deliverables'] as List).contains(
                    deliverable,
                  );
                  return DataCell(
                    Icon(
                      hasFeature ? Icons.check : Icons.close,
                      color: hasFeature ? Colors.green : Colors.red,
                      size: 5.w,
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }
}
