import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class VerificationResultCardWidget extends StatelessWidget {
  final String electionId;
  final Map<String, dynamic> result;
  final VoidCallback onViewBlockchainProof;

  const VerificationResultCardWidget({
    super.key,
    required this.electionId,
    required this.result,
    required this.onViewBlockchainProof,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = result['status'] as String;
    final isVerified = status == 'verified';

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isVerified
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? Icons.verified : Icons.error,
                      color: isVerified ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      isVerified ? 'Verified' : 'Failed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isVerified ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'link',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: onViewBlockchainProof,
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Vote Hash
          if (result['vote_hash'] != null) ...[
            Text(
              'Vote Hash',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            GestureDetector(
              onTap: () => _copyToClipboard(context, result['vote_hash']),
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        result['vote_hash'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.copy,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],

          // Blockchain Hash
          if (result['blockchain_hash'] != null) ...[
            Text(
              'Blockchain Hash',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            GestureDetector(
              onTap: () => _copyToClipboard(context, result['blockchain_hash']),
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        result['blockchain_hash'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.copy,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],

          // Block Number
          if (result['block_number'] != null) ...[
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'tag',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Block #${result['block_number']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
          ],

          // Transaction Hash
          if (result['transaction_hash'] != null) ...[
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'receipt_long',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'TX: ${_truncateHash(result['transaction_hash'])}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 2.h),

          // View Blockchain Proof Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewBlockchainProof,
              icon: CustomIconWidget(
                iconName: 'open_in_new',
                color: theme.colorScheme.primary,
                size: 18,
              ),
              label: Text('View Blockchain Proof'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _truncateHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
  }
}
