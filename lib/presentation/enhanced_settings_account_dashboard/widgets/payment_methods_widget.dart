import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PaymentMethodsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> paymentMethods;
  final VoidCallback onAdd;
  final Function(String) onRemove;
  final Function(String) onSetDefault;
  final VoidCallback onRefresh;

  const PaymentMethodsWidget({
    super.key,
    required this.paymentMethods,
    required this.onAdd,
    required this.onRemove,
    required this.onSetDefault,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: paymentMethods.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: paymentMethods.length + 1,
              itemBuilder: (context, index) {
                if (index == paymentMethods.length) {
                  return _buildAddButton();
                }
                return _buildPaymentMethodCard(context, paymentMethods[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 20.w, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'No payment methods',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context,
    Map<String, dynamic> method,
  ) {
    final isDefault = method['is_default'] == true;
    final cardBrand = method['card_brand'] ?? 'Card';
    final cardLast4 = method['card_last4'] ?? '****';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDefault ? AppTheme.primaryLight : Colors.grey.shade300,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.credit_card, size: 10.w, color: AppTheme.primaryLight),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$cardBrand •••• $cardLast4',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    if (isDefault) ...[
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Expires ${method['card_exp_month']}/${method['card_exp_year']}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'default') {
                onSetDefault(method['id']);
              } else if (value == 'remove') {
                _showRemoveConfirmation(context, method['id']);
              }
            },
            itemBuilder: (context) => [
              if (!isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Set as Default'),
                ),
              const PopupMenuItem(value: 'remove', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      margin: EdgeInsets.only(top: 2.h),
      child: OutlinedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Payment Method'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          side: BorderSide(color: AppTheme.primaryLight),
          foregroundColor: AppTheme.primaryLight,
        ),
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context, String methodId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: const Text(
          'Are you sure you want to remove this payment method?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove(methodId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
