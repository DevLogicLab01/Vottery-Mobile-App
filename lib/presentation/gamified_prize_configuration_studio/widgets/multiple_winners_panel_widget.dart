import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class MultipleWinnersPanelWidget extends StatefulWidget {
  final bool enabled;
  final List<Map<String, dynamic>> winnerSlots;
  final String prizeType;
  final double totalPrizeAmount;
  final Function(bool, List<Map<String, dynamic>>) onChanged;

  const MultipleWinnersPanelWidget({
    super.key,
    required this.enabled,
    required this.winnerSlots,
    required this.prizeType,
    required this.totalPrizeAmount,
    required this.onChanged,
  });

  @override
  State<MultipleWinnersPanelWidget> createState() =>
      _MultipleWinnersPanelWidgetState();
}

class _MultipleWinnersPanelWidgetState
    extends State<MultipleWinnersPanelWidget> {
  late bool _enabled;
  late List<Map<String, dynamic>> _slots;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _slots = List.from(widget.winnerSlots);

    if (_enabled && _slots.isEmpty) {
      _addWinnerSlot();
    }
  }

  void _addWinnerSlot() {
    setState(() {
      _slots.add({'rank': _slots.length + 1, 'percentage': 0.0});
    });
    _notifyChange();
  }

  void _removeWinnerSlot(int index) {
    setState(() {
      _slots.removeAt(index);
      // Reorder ranks
      for (int i = 0; i < _slots.length; i++) {
        _slots[i]['rank'] = i + 1;
      }
    });
    _notifyChange();
  }

  void _updatePercentage(int index, double percentage) {
    setState(() {
      _slots[index]['percentage'] = percentage;
    });
    _notifyChange();
  }

  void _distributeEqually() {
    if (_slots.isEmpty) return;

    final equalPercentage = 100.0 / _slots.length;
    setState(() {
      for (var slot in _slots) {
        slot['percentage'] = equalPercentage;
      }
    });
    _notifyChange();
  }

  void _notifyChange() {
    widget.onChanged(_enabled, _slots);
  }

  double _getTotalPercentage() {
    return _slots.fold(
      0.0,
      (sum, slot) => sum + (slot['percentage'] as double),
    );
  }

  String _getOrdinal(int rank) {
    if (rank % 100 >= 11 && rank % 100 <= 13) return '${rank}th';
    switch (rank % 10) {
      case 1:
        return '${rank}st';
      case 2:
        return '${rank}nd';
      case 3:
        return '${rank}rd';
      default:
        return '${rank}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPercentage = _getTotalPercentage();
    final isValid = totalPercentage == 100.0;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Multiple Winners',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _enabled,
                onChanged: (value) {
                  setState(() {
                    _enabled = value;
                    if (_enabled && _slots.isEmpty) {
                      _addWinnerSlot();
                    }
                  });
                  _notifyChange();
                },
                activeThumbColor: AppTheme.primaryColor,
              ),
            ],
          ),

          if (_enabled) ...[
            SizedBox(height: 1.h),
            Text(
              'Configure prize distribution for multiple winners',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),

            // Total Percentage Indicator
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isValid ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isValid ? Colors.green[300]! : Colors.orange[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle : Icons.warning,
                    color: isValid ? Colors.green : Colors.orange,
                    size: 18.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Total: ${totalPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isValid ? Colors.green[900] : Colors.orange[900],
                    ),
                  ),
                  if (!isValid) ...[
                    SizedBox(width: 2.w),
                    Text(
                      '(Must equal 100%)',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                  Spacer(),
                  TextButton.icon(
                    onPressed: _distributeEqually,
                    icon: Icon(Icons.balance, size: 14.sp),
                    label: Text('Distribute Equally'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),

            // Winner Slots List
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _slots.length,
              itemBuilder: (context, index) {
                final slot = _slots[index];
                final percentage = slot['percentage'] as double;
                final amount = (widget.totalPrizeAmount * percentage / 100);

                return Card(
                  margin: EdgeInsets.only(bottom: 1.h),
                  child: Padding(
                    padding: EdgeInsets.all(2.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                _getOrdinal(slot['rank']),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                'Winner ${slot['rank']}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_slots.length > 1)
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 18.sp),
                                color: Colors.red,
                                onPressed: () => _removeWinnerSlot(index),
                              ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Percentage: ${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(fontSize: 11.sp),
                                  ),
                                  Slider(
                                    value: percentage,
                                    min: 0,
                                    max: 100,
                                    divisions: 100,
                                    label: '${percentage.toStringAsFixed(1)}%',
                                    onChanged: (value) =>
                                        _updatePercentage(index, value),
                                    activeColor: AppTheme.primaryColor,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Amount',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '\$${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Add Winner Button
            if (_slots.length < 100)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addWinnerSlot,
                  icon: Icon(Icons.add),
                  label: Text('Add Winner Slot'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
