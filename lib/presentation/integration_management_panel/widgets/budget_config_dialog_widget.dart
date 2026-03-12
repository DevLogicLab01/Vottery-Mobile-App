import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BudgetConfigDialogWidget extends StatefulWidget {
  final String integrationName;
  final double currentWeeklyBudget;
  final double currentMonthlyBudget;

  const BudgetConfigDialogWidget({
    super.key,
    required this.integrationName,
    required this.currentWeeklyBudget,
    required this.currentMonthlyBudget,
  });

  @override
  State<BudgetConfigDialogWidget> createState() =>
      _BudgetConfigDialogWidgetState();
}

class _BudgetConfigDialogWidgetState extends State<BudgetConfigDialogWidget> {
  late TextEditingController _weeklyController;
  late TextEditingController _monthlyController;

  @override
  void initState() {
    super.initState();
    _weeklyController = TextEditingController(
      text: widget.currentWeeklyBudget.toStringAsFixed(2),
    );
    _monthlyController = TextEditingController(
      text: widget.currentMonthlyBudget.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _weeklyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Budget Configuration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.integrationName,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _weeklyController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Weekly Budget Cap (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _monthlyController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly Budget Cap (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Set budget caps to control spending. Alerts trigger at 80% usage.',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final weekly = double.tryParse(_weeklyController.text) ?? 0.0;
            final monthly = double.tryParse(_monthlyController.text) ?? 0.0;

            Navigator.pop(context, {'weekly': weekly, 'monthly': monthly});
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
