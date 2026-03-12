import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class RevenueShareFormWidget extends StatefulWidget {
  final double projectedRevenue;
  final double sharePercentage;
  final Function(Map<String, dynamic>) onDataChanged;

  const RevenueShareFormWidget({
    super.key,
    required this.projectedRevenue,
    required this.sharePercentage,
    required this.onDataChanged,
  });

  @override
  State<RevenueShareFormWidget> createState() => _RevenueShareFormWidgetState();
}

class _RevenueShareFormWidgetState extends State<RevenueShareFormWidget> {
  late TextEditingController _revenueController;
  late double _sharePercentage;

  @override
  void initState() {
    super.initState();
    _revenueController = TextEditingController(
      text: widget.projectedRevenue > 0
          ? widget.projectedRevenue.toStringAsFixed(2)
          : '',
    );
    _sharePercentage = widget.sharePercentage;
  }

  @override
  void dispose() {
    _revenueController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onDataChanged({
      'projectedRevenue': double.tryParse(_revenueController.text) ?? 0.0,
      'sharePercentage': _sharePercentage,
    });
  }

  double _calculateEstimatedPayout() {
    final revenue = double.tryParse(_revenueController.text) ?? 0.0;
    return revenue * (_sharePercentage / 100);
  }

  @override
  Widget build(BuildContext context) {
    final estimatedPayout = _calculateEstimatedPayout();

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
            'Revenue Sharing Details',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _revenueController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Projected Revenue',
              hintText: 'Estimated content revenue',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixText: '\$ ',
            ),
            onChanged: (_) {
              setState(() {});
              _notifyChange();
            },
          ),
          SizedBox(height: 2.h),
          Text(
            'Share Percentage: ${_sharePercentage.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _sharePercentage,
            min: 10,
            max: 90,
            divisions: 80,
            label: '${_sharePercentage.toStringAsFixed(0)}%',
            onChanged: (value) {
              setState(() => _sharePercentage = value);
              _notifyChange();
            },
            activeColor: AppTheme.primaryColor,
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Column(
              children: [
                Text(
                  'Estimated Payout',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '\$${estimatedPayout.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${_sharePercentage.toStringAsFixed(0)}% of \$${_revenueController.text.isEmpty ? "0.00" : double.tryParse(_revenueController.text)!.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
