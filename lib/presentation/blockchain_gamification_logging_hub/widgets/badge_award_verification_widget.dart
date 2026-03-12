import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class BadgeAwardVerificationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> badgeAwards;
  final VoidCallback onRefresh;

  const BadgeAwardVerificationWidget({
    super.key,
    required this.badgeAwards,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeAwards.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                size: 48.sp,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 2.h),
              Text(
                'No badge awards logged yet',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: badgeAwards.length,
        itemBuilder: (context, index) {
          final badge = badgeAwards[index];
          return _buildBadgeCard(context, badge);
        },
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, Map<String, dynamic> badge) {
    final isVerified = badge['verification_status'] == 'verified';
    final merkleRoot = badge['merkle_root'] ?? 'Generating...';
    final signature = badge['cryptographic_signature'] ?? 'Pending...';
    final createdAt = DateTime.parse(badge['created_at']);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.orange.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber.shade700,
                      size: 24.sp,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Badge Award',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isVerified ? Icons.verified : Icons.pending,
                        size: 12.sp,
                        color: isVerified
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        isVerified ? 'Verified' : 'Pending',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isVerified
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Text(
                  'Merkle Root: ',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Expanded(
                  child: Text(
                    merkleRoot.length > 15
                        ? '${merkleRoot.substring(0, 15)}...'
                        : merkleRoot,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.blue.shade700,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 16.sp),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: merkleRoot));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Merkle root copied')),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Text(
                  'Signature: ',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Expanded(
                  child: Text(
                    signature.length > 15
                        ? '${signature.substring(0, 15)}...'
                        : signature,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.purple.shade700,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Minted: ${createdAt.toString().substring(0, 19)}',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
