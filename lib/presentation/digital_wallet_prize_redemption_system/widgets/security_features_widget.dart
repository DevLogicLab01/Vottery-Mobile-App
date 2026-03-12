import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SecurityFeaturesWidget extends StatelessWidget {
  final VoidCallback onEnable2FA;
  final Function(double threshold) onSetAutoRedeem;

  const SecurityFeaturesWidget({
    super.key,
    required this.onEnable2FA,
    required this.onSetAutoRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),

          // 2FA setting
          ListTile(
            leading: const Icon(Icons.security, color: Colors.blue),
            title: const Text(
              '2FA Verification',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Required for withdrawals over \$1000',
              style: TextStyle(fontSize: 12),
            ),
            trailing: ElevatedButton(
              onPressed: onEnable2FA,
              child: const Text('Enable'),
            ),
          ),

          const Divider(),

          // Auto-redeem threshold
          ListTile(
            leading: const Icon(Icons.autorenew, color: Colors.green),
            title: const Text(
              'Auto-Redeem Threshold',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Automatically redeem when balance reaches threshold',
              style: TextStyle(fontSize: 12),
            ),
            trailing: ElevatedButton(
              onPressed: () => onSetAutoRedeem(100.0),
              child: const Text('Set'),
            ),
          ),

          const Divider(),

          // Withdrawal limits
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.orange),
            title: const Text(
              'Withdrawal Limits',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Daily: \$10,000 | Monthly: \$50,000',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
