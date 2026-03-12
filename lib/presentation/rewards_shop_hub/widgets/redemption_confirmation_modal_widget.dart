import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RedemptionConfirmationModalWidget extends StatelessWidget {
  final Map<String, dynamic> reward;
  final int currentVP;

  const RedemptionConfirmationModalWidget({
    super.key,
    required this.reward,
    required this.currentVP,
  });

  @override
  Widget build(BuildContext context) {
    final vpCost = reward['vp_cost'] as int;
    final title = reward['title'] as String;
    final description = reward['description'] as String;
    final newBalance = currentVP - vpCost;

    return AlertDialog(
      title: const Text('Confirm Redemption'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          Divider(),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Balance:', style: TextStyle(fontSize: 12.sp)),
              Text(
                '$currentVP VP',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cost:',
                style: TextStyle(fontSize: 12.sp, color: Colors.red),
              ),
              Text(
                '-$vpCost VP',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Divider(),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Balance:',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
              Text(
                '$newBalance VP',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
