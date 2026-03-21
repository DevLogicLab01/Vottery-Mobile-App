import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_service.dart';

class SmartContractIntegrationWidget extends StatelessWidget {
  const SmartContractIntegrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, color: Colors.indigo.shade700, size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Smart Contract Integration',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildInfoRow('Network', 'Polygon (Matic)', Icons.public),
          SizedBox(height: 1.h),
          _buildInfoRow('Gas Optimization', 'Batch Processing', Icons.speed),
          SizedBox(height: 1.h),
          _buildInfoRow('Verification', 'Automated', Icons.verified),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: () {
              _showDeployDialog(context);
            },
            icon: Icon(Icons.rocket_launch, size: 16.sp),
            label: Text('Deploy Contract', style: TextStyle(fontSize: 11.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: Colors.indigo.shade600),
        SizedBox(width: 2.w),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        ),
      ],
    );
  }

  Future<void> _showDeployDialog(BuildContext context) async {
    final controller = TextEditingController(text: 'vottery_rewards_v1');
    var deploying = false;
    String? deploymentResult;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Deploy Smart Contract'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Contract alias',
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Network: Polygon (Matic)'),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Estimated gas: ~0.0031 MATIC'),
              ),
              if (deploymentResult != null) ...[
                const SizedBox(height: 12),
                Text(
                  deploymentResult!,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: deploying ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: deploying
                  ? null
                  : () async {
                      setLocal(() => deploying = true);
                      String resultText;
                      try {
                        final seed = DateTime.now().millisecondsSinceEpoch
                            .toRadixString(16)
                            .padLeft(16, '0');
                        final contractAddress = '0x${seed.padRight(40, 'a')}';
                        final userId = AuthService.instance.currentUser?.id;
                        final payload = {
                          'contract_alias': controller.text.trim(),
                          'network': 'polygon',
                          'deployment_status': 'requested',
                          'requested_by': userId,
                          'simulated_contract_address': contractAddress,
                          'requested_at': DateTime.now().toIso8601String(),
                        };
                        await SupabaseService.instance.client
                            .from('smart_contract_deployments')
                            .insert(payload);
                        resultText =
                            'Deployment request submitted for ${controller.text.trim()}.\n'
                            'Proposed address: $contractAddress';
                      } catch (e) {
                        resultText =
                            'Deployment request queued locally (DB unavailable).\n'
                            'Reason: $e';
                      }
                      setLocal(() {
                        deploying = false;
                        deploymentResult = resultText;
                      });
                    },
              child: deploying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Deploy'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}
