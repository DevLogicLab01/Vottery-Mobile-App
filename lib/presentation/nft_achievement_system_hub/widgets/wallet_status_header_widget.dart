import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class WalletStatusHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> walletStatus;
  final Map<String, dynamic> currentTier;
  final Map<String, dynamic> mintingQueue;

  const WalletStatusHeaderWidget({
    super.key,
    required this.walletStatus,
    required this.currentTier,
    required this.mintingQueue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = walletStatus['connected'] as bool? ?? false;
    final wallets = walletStatus['wallets'] as List? ?? [];
    final tierName = currentTier['tier'] as String? ?? 'Bronze';
    final tierColor = Color(currentTier['color'] as int? ?? 0xFFCD7F32);
    final pending = mintingQueue['pending'] as int? ?? 0;
    final processing = mintingQueue['processing'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet connection status
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                isConnected
                    ? '${wallets.length} Wallet${wallets.length != 1 ? "s" : ""} Connected'
                    : 'No Wallet Connected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isConnected)
                Icon(
                  Icons.account_balance_wallet,
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
            ],
          ),

          SizedBox(height: 2.h),

          // Current tier and minting queue
          Row(
            children: [
              // Current tier
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Tier',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tierColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            tierName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 3.w),

              // Minting queue
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minting Queue',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${pending + processing} Pending',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
