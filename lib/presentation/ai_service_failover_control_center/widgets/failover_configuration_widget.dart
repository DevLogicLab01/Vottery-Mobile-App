import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FailoverConfigurationWidget extends StatelessWidget {
  final Function({required String fromProvider, required String toProvider})
  onTriggerFailover;

  const FailoverConfigurationWidget({
    super.key,
    required this.onTriggerFailover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Failover Configuration',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildConfigSection(
            title: 'Automatic Switching Rules',
            icon: Icons.autorenew,
            children: [
              _buildConfigItem(
                label: 'Failure Detection Threshold',
                value: '2 seconds',
                description:
                    'Requests exceeding this threshold trigger failover',
              ),
              _buildConfigItem(
                label: 'Max Retry Attempts',
                value: '3 retries',
                description: 'Number of retries before failover activation',
              ),
              _buildConfigItem(
                label: 'Failover Target',
                value: 'Gemini (Automatic)',
                description: 'Default backup service for all providers',
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildConfigSection(
            title: 'Retry Policy (Exponential Backoff)',
            icon: Icons.schedule,
            children: [
              _buildConfigItem(
                label: 'Initial Delay',
                value: '500ms',
                description: 'First retry delay',
              ),
              _buildConfigItem(
                label: 'Backoff Multiplier',
                value: '2.0x',
                description: 'Delay multiplier for each retry',
              ),
              _buildConfigItem(
                label: 'Retry Sequence',
                value: '500ms → 1s → 2s',
                description: 'Exponential backoff progression',
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildConfigSection(
            title: 'Service Priority Rankings',
            icon: Icons.format_list_numbered,
            children: [
              _buildPriorityItem(1, 'OpenAI GPT-4', 'Primary'),
              _buildPriorityItem(2, 'Anthropic Claude', 'Secondary'),
              _buildPriorityItem(3, 'Perplexity Sonar', 'Tertiary'),
              _buildPriorityItem(4, 'Google Gemini', 'Failover Backup'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20.sp, color: Colors.deepPurple),
            SizedBox(width: 2.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildConfigItem({
    required String label,
    required String value,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            description,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityItem(int rank, String service, String role) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: rank == 1
                  ? Colors.amber
                  : rank == 2
                  ? Colors.grey.shade400
                  : rank == 3
                  ? Colors.brown.shade300
                  : Colors.blue.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
