import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widgets/custom_icon_widget.dart';

class BlockchainProofWidget extends StatelessWidget {
  final Map<String, dynamic> result;

  const BlockchainProofWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'link',
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Blockchain Proof',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Status
                  _buildSection(
                    theme,
                    'Verification Status',
                    Icons.verified,
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            result['verification_status'] ?? 'Verified',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Vote Hash
                  if (result['vote_hash'] != null)
                    _buildHashSection(
                      theme,
                      'Vote Hash',
                      result['vote_hash'],
                      context,
                    ),

                  SizedBox(height: 3.h),

                  // Blockchain Hash
                  if (result['blockchain_hash'] != null)
                    _buildHashSection(
                      theme,
                      'Blockchain Hash',
                      result['blockchain_hash'],
                      context,
                    ),

                  SizedBox(height: 3.h),

                  // Block Number
                  if (result['block_number'] != null)
                    _buildSection(
                      theme,
                      'Block Number',
                      Icons.tag,
                      Text(
                        '#${result['block_number']}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                  SizedBox(height: 3.h),

                  // Transaction Hash
                  if (result['transaction_hash'] != null)
                    _buildHashSection(
                      theme,
                      'Transaction Hash',
                      result['transaction_hash'],
                      context,
                    ),

                  SizedBox(height: 3.h),

                  // Immutable Audit Log Link
                  _buildSection(
                    theme,
                    'Immutable Audit Log',
                    Icons.description,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This vote is permanently recorded in an immutable blockchain audit log. The cryptographic proof ensures vote integrity and prevents tampering.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        ElevatedButton.icon(
                          onPressed: () => _openBlockchainExplorer(context),
                          icon: Icon(Icons.open_in_new),
                          label: Text('View on Blockchain Explorer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            SizedBox(width: 2.w),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        content,
      ],
    );
  }

  Widget _buildHashSection(
    ThemeData theme,
    String title,
    String hash,
    BuildContext context,
  ) {
    return _buildSection(
      theme,
      title,
      Icons.fingerprint,
      GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: hash));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hash,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Icon(
                Icons.copy,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBlockchainExplorer(BuildContext context) async {
    final hash = result['transaction_hash']?.toString() ?? '';
    if (hash.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transaction hash available')),
      );
      return;
    }

    final uri = hash.startsWith('0x')
        ? Uri.parse('https://etherscan.io/tx/$hash')
        : Uri.parse('https://explorer.solana.com/tx/$hash');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) return;

    await Clipboard.setData(ClipboardData(text: hash));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open explorer. Transaction hash copied.'),
      ),
    );
  }
}
